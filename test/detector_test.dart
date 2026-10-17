import 'package:flutter_test/flutter_test.dart';
import 'package:langgananku/models/subscription.dart';
import 'package:langgananku/services/detector.dart';
import 'package:langgananku/utils/format.dart';

void main() {
  test('parseRupiah', () {
    expect(Detector.parseRupiah('54.000'), 54000);
    expect(Detector.parseRupiah('54.000,00'), 54000);
    expect(Detector.parseRupiah('54,990.00'), 54990);
    expect(Detector.parseRupiah('1.250.000'), 1250000);
  });

  test('parseDate', () {
    expect(Detector.parseDate('pada 05/10/2026'), DateTime(2026, 10, 5));
    expect(Detector.parseDate('12 Okt 2026'), DateTime(2026, 10, 12));
    expect(Detector.parseDate('2026-01-31'), DateTime(2026, 1, 31));
  });

  test('detect groups monthly charges and predicts next due', () {
    final msgs = [
      RawMessage('Pembayaran Rp65.000 ke NETFLIX.COM berhasil 05/08/2026', DateTime(2026, 8, 5)),
      RawMessage('Pembayaran Rp65.000 ke NETFLIX.COM berhasil 05/09/2026', DateTime(2026, 9, 5)),
      RawMessage('Jatuh tempo kartu kredit Rp1.200.000', DateTime(2026, 9, 6)),
    ];
    final r = Detector.detect(msgs, []);
    expect(r.length, 1);
    expect(r.first.name, 'Netflix');
    expect(r.first.cycle, BillingCycle.monthly);
    expect(r.first.amount, 65000);
  });

  test('addMonths keeps anchor day', () {
    final feb = addMonths(DateTime(2026, 1, 31), 1, anchorDay: 31);
    expect(feb, DateTime(2026, 2, 28));
    expect(addMonths(feb, 1, anchorDay: 31), DateTime(2026, 3, 31));
  });
}
