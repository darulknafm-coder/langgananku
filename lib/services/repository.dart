import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/catalog.dart';
import '../models/subscription.dart';
import '../utils/format.dart';
import 'notification_service.dart';

/// Penyimpanan lokal di perangkat (mode tanpa akun). Semua data tetap di HP.
class Repo extends ChangeNotifier {
  Repo._();
  static final Repo instance = Repo._();

  static const _kSubs = 'subs_v1';
  static const _kAlerts = 'alerts_v1';
  static const _kSettings = 'settings_v1';

  final List<Subscription> subs = [];
  final List<PriceAlert> alerts = [];
  bool remindersEnabled = true;
  int reminderHour = 9;
  bool onboarded = false;
  double usdRate = 16500;

  SharedPreferences? _prefs;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final p = _prefs!;
    try {
      final raw = p.getString(_kSubs);
      if (raw != null) {
        subs
          ..clear()
          ..addAll((jsonDecode(raw) as List)
              .map((e) => Subscription.fromJson(Map<String, dynamic>.from(e as Map))));
      }
      final ra = p.getString(_kAlerts);
      if (ra != null) {
        alerts
          ..clear()
          ..addAll((jsonDecode(ra) as List)
              .map((e) => PriceAlert.fromJson(Map<String, dynamic>.from(e as Map))));
      }
      final rs = p.getString(_kSettings);
      if (rs != null) {
        final s = jsonDecode(rs) as Map<String, dynamic>;
        remindersEnabled = (s['remindersEnabled'] as bool?) ?? true;
        reminderHour = (s['reminderHour'] as int?) ?? 9;
        onboarded = (s['onboarded'] as bool?) ?? false;
        usdRate = ((s['usdRate'] as num?) ?? 16500).toDouble();
      }
    } catch (_) {
      // Data rusak → mulai bersih, jangan bikin app crash.
    }
    Subscription.usdRate = usdRate;
    // Data contoh untuk pratinjau/screenshot: flutter build ... --dart-define=DEMO=true
    if (const bool.fromEnvironment('DEMO') && subs.isEmpty) {
      _seedDemo();
    }
    for (final s in subs) {
      s.rollForward();
    }
    await _persist();
  }

  void _seedDemo() {
    final today = DateTime.now();
    DateTime d(int days) => DateTime(today.year, today.month, today.day + days);
    Subscription mk(String key, double amount, int dueIn,
        {String pay = 'Kartu Kredit', Usage usage = Usage.often, int shared = 1, double? oldPrice}) {
      final c = catalogByKey(key)!;
      final due = d(dueIn);
      return Subscription(
        id: newId(),
        name: c.name,
        category: c.category,
        amount: amount,
        cycle: BillingCycle.monthly,
        nextDue: due,
        paymentMethod: pay,
        cancelUrl: c.cancelUrl,
        color: c.color,
        usage: usage,
        sharedWith: shared,
        catalogKey: key,
        history: [
          if (oldPrice != null) PricePoint(d(-150), oldPrice),
          PricePoint(d(oldPrice != null ? -30 : -90), amount),
        ],
      );
    }

    final netflix = mk('netflix', 65000, 2, pay: 'GoPay', shared: 2, oldPrice: 54000);
    subs.addAll([
      netflix,
      mk('spotify', 54990, 9),
      mk('chatgpt', 330000, 14),
      mk('claude', 20, 20, usage: Usage.rarely)
        ..currency = 'USD'
        ..history = [PricePoint(d(-90), 20)],
      mk('canva', 95000, 5, pay: 'DANA'),
      mk('googleone', 26900, 24, pay: 'Google Play'),
      mk('indihome', 300000, 11, pay: 'Transfer Bank'),
      mk('vidio', 39000, 17, pay: 'Pulsa', usage: Usage.rarely),
      mk('youtube', 59000, 4, pay: 'Google Play')..trialEnd = d(4),
    ]);
    alerts.add(PriceAlert(
        subId: netflix.id, name: 'Netflix', oldAmount: 54000, newAmount: 65000, date: d(-30)));
  }

  Future<void> _persist() async {
    final p = _prefs ?? await SharedPreferences.getInstance();
    await p.setString(_kSubs, jsonEncode(subs.map((s) => s.toJson()).toList()));
    await p.setString(_kAlerts, jsonEncode(alerts.map((a) => a.toJson()).toList()));
    await p.setString(
        _kSettings,
        jsonEncode({
          'remindersEnabled': remindersEnabled,
          'reminderHour': reminderHour,
          'onboarded': onboarded,
          'usdRate': usdRate,
        }));
    // Jangan pernah menahan UI menunggu penjadwalan notifikasi.
    unawaited(NotificationService.reschedule(subs, enabled: remindersEnabled, hour: reminderHour)
        .timeout(const Duration(seconds: 20), onTimeout: () {})
        .catchError((_) {}));
  }

  /// Jadwalkan ulang pengingat (dipanggil setelah notifikasi siap).
  Future<void> refreshReminders() async {
    try {
      await NotificationService.reschedule(subs, enabled: remindersEnabled, hour: reminderHour)
          .timeout(const Duration(seconds: 20));
    } catch (_) {}
  }

  Future<void> _commit() async {
    notifyListeners();
    await _persist();
  }

  // ---------- Ringkasan ----------
  List<Subscription> get active => subs.where((s) => s.active).toList();
  double get monthlyTotal => active.fold<double>(0, (a, s) => a + s.myMonthlyCost);
  double get yearlyTotal => monthlyTotal * 12;
  List<PriceAlert> get unseenAlerts => alerts.where((a) => !a.seen).toList();

  List<Subscription> upcoming([int n = 5]) {
    final list = active..sort((a, b) => a.nextDue.compareTo(b.nextDue));
    return list.take(n).toList();
  }

  Map<String, double> byCategory() {
    final m = <String, double>{};
    for (final s in active) {
      m[s.category] = (m[s.category] ?? 0) + s.myMonthlyCost;
    }
    final entries = m.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(entries);
  }

  /// Kelompok langganan dengan fungsi sama (mis. 2 chatbot AI, 3 VPN).
  Map<String, List<Subscription>> duplicates() {
    final m = <String, List<Subscription>>{};
    for (final s in active) {
      if (kDuplicateProne.contains(s.category)) {
        m.putIfAbsent(s.category, () => []).add(s);
      }
    }
    m.removeWhere((_, v) => v.length < 2);
    return m;
  }

  /// Hemat per tahun bila pindah ke paket tahunan (pakai harga katalog).
  double annualSaving(Subscription s) {
    final c = catalogByKey(s.catalogKey);
    if (c?.yearly == null || s.cycle == BillingCycle.yearly) return 0;
    final diff = s.yearlyCost - c!.yearly!;
    return diff > 0 ? diff : 0;
  }

  double get potentialMonthlySaving {
    var total = 0.0;
    for (final s in active) {
      if (s.usage == Usage.rarely) {
        total += s.myMonthlyCost;
      } else {
        total += annualSaving(s) / 12;
      }
    }
    // + duplikasi: anggap yang termurah di tiap kelompok bisa dihentikan
    duplicates().forEach((_, list) {
      final notRare = list.where((s) => s.usage != Usage.rarely).toList();
      if (notRare.length >= 2) {
        notRare.sort((a, b) => a.myMonthlyCost.compareTo(b.myMonthlyCost));
        total += notRare.first.myMonthlyCost;
      }
    });
    return total;
  }

  // ---------- Perubahan data ----------
  String newId() =>
      '${DateTime.now().microsecondsSinceEpoch}${Random().nextInt(9999)}';

  Future<void> add(Subscription s) async {
    s.rollForward();
    subs.add(s);
    await _commit();
  }

  /// Simpan perubahan. Bila nominal berubah → catat riwayat harga,
  /// dan bila naik → buat peringatan kenaikan harga.
  Future<void> update(Subscription s, {double? newAmount}) async {
    if (newAmount != null && (newAmount - s.amount).abs() >= 1) {
      _recordPrice(s, newAmount);
    }
    s.rollForward();
    await _commit();
  }

  void _recordPrice(Subscription s, double newAmount) {
    final old = s.amount;
    s.history.add(PricePoint(DateTime.now(), newAmount));
    s.amount = newAmount;
    if (newAmount > old) {
      alerts.insert(
          0,
          PriceAlert(
              subId: s.id,
              name: s.name,
              oldAmount: old,
              newAmount: newAmount,
              currency: s.currency,
              date: DateTime.now()));
      NotificationService.showNow('Harga ${s.name} naik',
          'Dari ${money(old, s.currency)} menjadi ${money(newAmount, s.currency)}. Cek apakah masih layak.');
    }
  }

  /// Dipakai oleh hasil pindai SMS/email: perbarui harga + jatuh tempo.
  Future<void> applyDetected(Subscription s, double amount, DateTime nextDue) async {
    // Nominal hasil pindai selalu Rupiah; untuk langganan USD cukup perbarui tanggal.
    if (!s.isUsd && (amount - s.amount).abs() >= 1) _recordPrice(s, amount);
    s.trialEnd = null; // sudah ada tagihan nyata → trial selesai
    s.nextDue = nextDue;
    s.anchorDay = nextDue.day;
    s.rollForward();
    await _commit();
  }

  Future<void> remove(Subscription s) async {
    subs.removeWhere((x) => x.id == s.id);
    alerts.removeWhere((a) => a.subId == s.id);
    await _commit();
  }

  /// Kembalikan langganan yang baru dihapus (tombol "Urungkan").
  Future<void> restore(Subscription s, List<PriceAlert> removedAlerts, int index) async {
    if (subs.any((x) => x.id == s.id)) return;
    subs.insert(index.clamp(0, subs.length), s);
    alerts.addAll(removedAlerts);
    alerts.sort((a, b) => b.date.compareTo(a.date));
    await _commit();
  }

  Future<void> setUsdRate(double rate) async {
    if (rate <= 0) return;
    usdRate = rate;
    Subscription.usdRate = rate;
    await _commit();
  }

  Future<void> setActive(Subscription s, bool v) async {
    s.active = v;
    await _commit();
  }

  Future<void> dismissAlert(PriceAlert a) async {
    a.seen = true;
    await _commit();
  }

  Future<void> setReminders({bool? enabled, int? hour}) async {
    if (enabled != null) remindersEnabled = enabled;
    if (hour != null) reminderHour = hour;
    await _commit();
  }

  Future<void> completeOnboarding() async {
    onboarded = true;
    await _commit();
  }

  String exportJson() => const JsonEncoder.withIndent('  ').convert({
        'app': 'LanggananKu',
        'version': 2,
        'exportedAt': DateTime.now().toIso8601String(),
        'usdRate': usdRate,
        'subs': subs.map((s) => s.toJson()).toList(),
        'alerts': alerts.map((a) => a.toJson()).toList(),
      });

  Future<int> importJson(String raw) async {
    final j = jsonDecode(raw) as Map<String, dynamic>;
    final list = (j['subs'] as List)
        .map((e) => Subscription.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    subs
      ..clear()
      ..addAll(list);
    final al = j['alerts'] as List?;
    if (al != null) {
      alerts
        ..clear()
        ..addAll(al.map((e) => PriceAlert.fromJson(Map<String, dynamic>.from(e as Map))));
    }
    final rate = (j['usdRate'] as num?)?.toDouble();
    if (rate != null && rate > 0) {
      usdRate = rate;
      Subscription.usdRate = rate;
    }
    for (final s in subs) {
      s.rollForward();
    }
    await _commit();
    return list.length;
  }

  Future<void> clearAll() async {
    subs.clear();
    alerts.clear();
    await _commit();
  }
}
