import '../data/catalog.dart';
import '../models/subscription.dart';
import '../utils/format.dart';

/// Pesan mentah (SMS / email / nota) yang akan dipindai — semua diproses
/// di perangkat, tidak dikirim ke server mana pun.
class RawMessage {
  final String body;
  final DateTime date;
  final String sender;
  RawMessage(this.body, this.date, [this.sender = '']);
}

class DetectedCharge {
  final String name;
  final CatalogItem? item;
  final double amount;
  final DateTime date;
  final String raw;
  final bool yearlyHint;
  DetectedCharge(this.name, this.item, this.amount, this.date, this.raw, this.yearlyHint);
}

class DetectedSubscription {
  String name;
  final CatalogItem? item;
  double amount;
  BillingCycle cycle;
  final DateTime lastCharge;
  DateTime nextDue;
  final int occurrences;
  final Subscription? existing;
  bool selected = true;

  DetectedSubscription({
    required this.name,
    required this.item,
    required this.amount,
    required this.cycle,
    required this.lastCharge,
    required this.nextDue,
    required this.occurrences,
    required this.existing,
  });

  bool get isNew => existing == null;
  bool get priceChanged =>
      existing != null && !existing!.isUsd && (existing!.amount - amount).abs() >= 1;
}

class Detector {
  static final RegExp _amountRe =
      RegExp(r'(?:Rp\.?|IDR)\s*([0-9][0-9.,]*)', caseSensitive: false);

  static final RegExp _recurringRe = RegExp(
      r'langganan|berlangganan|subscription|subscribe|perpanjang|renewal|renew|auto ?debit|autodebet|recurring|membership|premium|paket',
      caseSensitive: false);

  static final RegExp _paymentRe = RegExp(
      r'transaksi|pembayaran|payment|tagihan|charged|ditagih|debit|berhasil|receipt|nota|invoice|bayar',
      caseSensitive: false);

  static final RegExp _merchantRe = RegExp(
      r'(?:di|ke|merchant|kepada|pada|at|to)\s*:?\s+([A-Z][A-Za-z0-9&*.\-]{2,}(?:\s[A-Z][A-Za-z0-9&*.\-]+){0,2})');

  static final RegExp _yearlyRe =
      RegExp(r'tahunan|per tahun|/thn|annual|yearly|12 bulan', caseSensitive: false);

  static const Map<String, int> _months = {
    'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'mei': 5, 'may': 5, 'jun': 6,
    'jul': 7, 'agu': 8, 'agt': 8, 'aug': 8, 'sep': 9, 'okt': 10, 'oct': 10,
    'nov': 11, 'nop': 11, 'des': 12, 'dec': 12,
  };

  /// "54.000" → 54000 · "54.000,00" → 54000 · "54,990.00" → 54990
  static double? parseRupiah(String s) {
    var t = s.trim().replaceAll(RegExp(r'[.,]+$'), '');
    if (RegExp(r'[.,]\d{2}$').hasMatch(t) && t.length > 3) {
      t = t.substring(0, t.length - 3);
    }
    t = t.replaceAll(RegExp(r'[.,]'), '');
    return double.tryParse(t);
  }

  /// Cari tanggal di dalam teks: 16/10/2026, 16-10-26, 16 Okt 2026, 2026-10-16.
  static DateTime? parseDate(String text) {
    final iso = RegExp(r'(20\d{2})-(\d{1,2})-(\d{1,2})').firstMatch(text);
    if (iso != null) {
      return _safeDate(int.parse(iso.group(1)!), int.parse(iso.group(2)!), int.parse(iso.group(3)!));
    }
    final dmy = RegExp(r'\b(\d{1,2})[/\-.](\d{1,2})[/\-.](\d{2,4})\b').firstMatch(text);
    if (dmy != null) {
      var y = int.parse(dmy.group(3)!);
      if (y < 100) y += 2000;
      return _safeDate(y, int.parse(dmy.group(2)!), int.parse(dmy.group(1)!));
    }
    final named = RegExp(r'\b(\d{1,2})\s+([A-Za-z]{3})[a-z]*\.?\s+(20\d{2})\b').firstMatch(text);
    if (named != null) {
      final m = _months[named.group(2)!.toLowerCase()];
      if (m != null) {
        return _safeDate(int.parse(named.group(3)!), m, int.parse(named.group(1)!));
      }
    }
    return null;
  }

  static DateTime? _safeDate(int y, int m, int d) {
    if (m < 1 || m > 12 || d < 1 || d > 31) return null;
    final dt = DateTime(y, m, d);
    if (dt.month != m) return null;
    return dt;
  }

  /// Ambil satu tagihan dari satu pesan (atau null bila bukan tagihan langganan).
  static DetectedCharge? parseMessage(RawMessage msg) {
    final text = msg.body;
    final amountMatch = _amountRe.firstMatch(text);
    if (amountMatch == null) return null;
    final amount = parseRupiah(amountMatch.group(1)!);
    if (amount == null || amount < 1000) return null;

    final item = matchCatalog('$text ${msg.sender}');
    String? name = item?.name;
    if (name == null) {
      // Tidak ada di katalog → hanya terima bila jelas tagihan berulang.
      if (!_recurringRe.hasMatch(text) || !_paymentRe.hasMatch(text)) return null;
      final m = _merchantRe.firstMatch(text);
      name = m?.group(1)?.trim() ?? 'Langganan tak dikenal';
    }
    final date = parseDate(text) ?? msg.date;
    return DetectedCharge(name, item, amount, date, text, _yearlyRe.hasMatch(text));
  }

  /// Satukan banyak pesan menjadi daftar langganan (dikelompokkan per layanan),
  /// memperkirakan siklus tagih dan tanggal jatuh tempo berikutnya,
  /// serta mencocokkan dengan langganan yang sudah tercatat.
  static List<DetectedSubscription> detect(
      List<RawMessage> messages, List<Subscription> existing) {
    final groups = <String, List<DetectedCharge>>{};
    for (final m in messages) {
      final c = parseMessage(m);
      if (c == null) continue;
      final key = c.item?.key ?? c.name.toLowerCase();
      groups.putIfAbsent(key, () => []).add(c);
    }

    final result = <DetectedSubscription>[];
    groups.forEach((key, charges) {
      charges.sort((a, b) => a.date.compareTo(b.date));
      final last = charges.last;

      var cycle = last.yearlyHint ? BillingCycle.yearly : BillingCycle.monthly;
      if (charges.length >= 2) {
        final gaps = <int>[];
        for (var i = 1; i < charges.length; i++) {
          final g = charges[i].date.difference(charges[i - 1].date).inDays;
          if (g > 2) gaps.add(g);
        }
        if (gaps.isNotEmpty) {
          final avg = gaps.reduce((a, b) => a + b) / gaps.length;
          cycle = avg <= 10
              ? BillingCycle.weekly
              : avg <= 45
                  ? BillingCycle.monthly
                  : avg <= 120
                      ? BillingCycle.quarterly
                      : BillingCycle.yearly;
        }
      }

      final anchor = last.date.day;
      var next = cycle.nextFrom(dateOnly(last.date), anchor);
      final today = dateOnly(DateTime.now());
      var guard = 0;
      while (next.isBefore(today) && guard < 500) {
        next = cycle.nextFrom(next, anchor);
        guard++;
      }

      Subscription? match;
      for (final s in existing) {
        if ((last.item != null && s.catalogKey == last.item!.key) ||
            s.name.toLowerCase() == last.name.toLowerCase()) {
          match = s;
          break;
        }
      }

      result.add(DetectedSubscription(
        name: last.name,
        item: last.item,
        amount: last.amount,
        cycle: cycle,
        lastCharge: last.date,
        nextDue: next,
        occurrences: charges.length,
        existing: match,
      ));
    });

    // Yang sudah tercatat dan harganya sama tidak perlu ditampilkan lagi.
    result.removeWhere((d) => d.existing != null && !d.priceChanged);
    result.sort((a, b) => a.name.compareTo(b.name));
    return result;
  }

  /// Pecah teks tempelan (beberapa SMS/email sekaligus) menjadi pesan terpisah.
  static List<RawMessage> splitPasted(String text) {
    final parts = text
        .split(RegExp(r'\n\s*\n|-{3,}'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty);
    return [for (final p in parts) RawMessage(p, DateTime.now())];
  }
}
