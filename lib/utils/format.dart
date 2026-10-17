import 'package:intl/intl.dart';

final NumberFormat _rp =
    NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

/// Rp54.000
String rupiah(num v) => _rp.format(v);

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
