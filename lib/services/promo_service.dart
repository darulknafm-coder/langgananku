import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/subscription.dart';
import '../utils/format.dart';

/// Data paket & promo per layanan. Sumber utamanya file `promos.json` di
/// GitHub Pages, jadi bisa diperbarui tanpa merilis ulang aplikasi.
const String kPromoUrl = 'https://darulknafm-coder.github.io/langgananku/promos.json';

class PromoPlan {
  final String name;
  final double price;
  final String currency;
  final BillingCycle cycle;
  final String? note;
  PromoPlan(this.name, this.price, this.currency, this.cycle, this.note);

  String get priceLabel => '${money(price, currency)}${cycle.perLabel}';

  /// Biaya per bulan dalam Rupiah (untuk perbandingan).
  double get monthlyIdr =>
      (currency == 'USD' ? price * Subscription.usdRate : price) * cycle.perMonth;

  factory PromoPlan.fromJson(Map<String, dynamic> j) => PromoPlan(
        j['name'] as String,
        (j['price'] as num).toDouble(),
        (j['currency'] as String?) ?? 'IDR',
        BillingCycle.values.firstWhere((c) => c.name == j['cycle'],
            orElse: () => BillingCycle.monthly),
        j['note'] as String?,
      );
}

class ServicePromo {
  final String key;
  final String? offer;
  final String? offerNote;
  final String url;
  final String source;
  final List<PromoPlan> plans;
  ServicePromo(this.key, this.offer, this.offerNote, this.url, this.source, this.plans);

  PromoPlan? get cheapest {
    if (plans.isEmpty) return null;
    return plans.reduce((a, b) => a.monthlyIdr <= b.monthlyIdr ? a : b);
  }

  factory ServicePromo.fromJson(Map<String, dynamic> j) => ServicePromo(
        j['key'] as String,
        j['offer'] as String?,
        j['offerNote'] as String?,
        j['url'] as String,
        (j['source'] as String?) ?? '',
        ((j['plans'] as List?) ?? [])
            .map((e) => PromoPlan.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
}

class PromoService extends ChangeNotifier {
  PromoService._();
  static final PromoService instance = PromoService._();
  static const _kCache = 'promos_cache_v1';

  List<ServicePromo> services = [];
  String updated = '';
  String note = '';
  bool online = false; // true bila data terbaru berhasil diambil

  ServicePromo? forKey(String? key) {
    if (key == null) return null;
    for (final s in services) {
      if (s.key == key) return s;
    }
    return null;
  }

  bool _parse(String raw) {
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      services = ((j['services'] as List?) ?? [])
          .map((e) => ServicePromo.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      updated = (j['updated'] as String?) ?? '';
      note = (j['note'] as String?) ?? '';
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Muat cache/bawaan dulu (cepat), lalu coba ambil versi terbaru dari internet.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_kCache);
    if (cached == null || !_parse(cached)) {
      try {
        _parse(await rootBundle.loadString('assets/data/promos.json'));
      } catch (_) {}
    }
    notifyListeners();
    await refresh();
  }

  Future<void> refresh() async {
    try {
      final res = await http.get(Uri.parse(kPromoUrl)).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200 && _parse(utf8.decode(res.bodyBytes))) {
        online = true;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_kCache, utf8.decode(res.bodyBytes));
        notifyListeners();
      }
    } catch (_) {
      // offline → tetap pakai cache/bawaan
    }
  }
}
