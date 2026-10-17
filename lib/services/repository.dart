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
      }
    } catch (_) {
      // Data rusak → mulai bersih, jangan bikin app crash.
    }
    for (final s in subs) {
      s.rollForward();
    }
    await _persist();
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
        }));
    await NotificationService.reschedule(subs,
        enabled: remindersEnabled, hour: reminderHour);
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
              date: DateTime.now()));
      NotificationService.showNow('Harga ${s.name} naik',
          'Dari ${rupiah(old)} menjadi ${rupiah(newAmount)}. Cek apakah masih layak.');
    }
  }

  /// Dipakai oleh hasil pindai SMS/email: perbarui harga + jatuh tempo.
  Future<void> applyDetected(Subscription s, double amount, DateTime nextDue) async {
    if ((amount - s.amount).abs() >= 1) _recordPrice(s, amount);
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
        'version': 1,
        'subs': subs.map((s) => s.toJson()).toList(),
      });

  Future<int> importJson(String raw) async {
    final j = jsonDecode(raw) as Map<String, dynamic>;
    final list = (j['subs'] as List)
        .map((e) => Subscription.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    subs
      ..clear()
      ..addAll(list);
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
