import 'package:intl/intl.dart';

final NumberFormat _rp =
    NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

/// Rp54.000
String rupiah(num v) => _rp.format(v);

final NumberFormat _usd =
    NumberFormat.currency(locale: 'en_US', symbol: 'US\$', decimalDigits: 2);

/// US$19.99 (tanpa ",00" bila bulat: US$20)
String dolar(num v) {
  final s = _usd.format(v);
  return s.endsWith('.00') ? s.substring(0, s.length - 3) : s;
}

/// Format nominal sesuai mata uang ('IDR' / 'USD').
String money(num v, String currency) => currency == 'USD' ? dolar(v) : rupiah(v);

/// Baca nominal dolar: "20", "19.99", "19,99", "US$ 20".
double? parseUsd(String s) {
  final t = s.replaceAll(RegExp(r'[^0-9.,]'), '').replaceAll(',', '.');
  return double.tryParse(t);
}

String tanggal(DateTime d) => DateFormat('d MMM yyyy', 'id_ID').format(d);

String tanggalPendek(DateTime d) => DateFormat('d MMM', 'id_ID').format(d);

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

int daysUntil(DateTime d) =>
    dateOnly(d).difference(dateOnly(DateTime.now())).inDays;

String sisaHari(DateTime d) {
  final n = daysUntil(d);
  if (n == 0) return 'Hari ini';
  if (n == 1) return 'Besok';
  if (n < 0) return '${-n} hari lalu';
  return '$n hari lagi';
}

/// Menambah bulan dengan menjaga "tanggal tagih" asli (anchorDay),
/// mis. tagihan tiap tanggal 31 → 29 Feb → 31 Mar.
DateTime addMonths(DateTime d, int months, {int? anchorDay}) {
  final total = d.month - 1 + months;
  final y = d.year + (total ~/ 12);
  final m = total % 12 + 1;
  final lastDay = DateTime(y, m + 1, 0).day;
  final want = anchorDay ?? d.day;
  return DateTime(y, m, want > lastDay ? lastDay : want);
}
