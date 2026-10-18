import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:langgananku/models/subscription.dart';
import 'package:langgananku/utils/format.dart';

void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));

  test('format dolar dan parse', () {
    expect(dolar(20), 'US\$20');
    expect(dolar(19.99), 'US\$19.99');
    expect(parseUsd('19,99'), 19.99);
    expect(parseUsd('US\$ 20'), 20);
  });

  test('langganan USD dihitung dengan kurs', () {
    Subscription.usdRate = 16000;
    final s = Subscription(
      id: '1',
      name: 'Claude Pro',
      category: 'AI',
      amount: 20,
      cycle: BillingCycle.monthly,
      nextDue: DateTime.now().add(const Duration(days: 5)),
      currency: 'USD',
    );
    expect(s.amountIdr, 320000);
    expect(s.monthlyCost, 320000);
    expect(s.amountLabel, 'US\$20');
  });

  test('trial dan simpan/muat JSON', () {
    final end = dateOnly(DateTime.now().add(const Duration(days: 3)));
    final s = Subscription(
      id: '2',
      name: 'YouTube Premium',
      category: 'Streaming Video',
      amount: 59000,
      cycle: BillingCycle.monthly,
      nextDue: end,
      trialEnd: end,
    );
    expect(s.onTrial, isTrue);
    final back = Subscription.fromJson(s.toJson());
    expect(back.onTrial, isTrue);
    expect(back.currency, 'IDR');

    // Data versi lama (tanpa field baru) tetap terbaca.
    final old = Map<String, dynamic>.from(s.toJson())
      ..remove('currency')
      ..remove('trialEnd');
    final o = Subscription.fromJson(old);
    expect(o.currency, 'IDR');
    expect(o.onTrial, isFalse);
  });

  test('trial yang sudah lewat tidak dihitung trial', () {
    final s = Subscription(
      id: '3',
      name: 'X',
      category: 'Lainnya',
      amount: 1000,
      cycle: BillingCycle.monthly,
      nextDue: DateTime.now().add(const Duration(days: 20)),
      trialEnd: DateTime.now().subtract(const Duration(days: 10)),
    );
    expect(s.onTrial, isFalse);
  });
}
