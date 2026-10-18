import '../utils/format.dart';

enum BillingCycle { weekly, monthly, quarterly, yearly }

extension BillingCycleX on BillingCycle {
  String get label => switch (this) {
        BillingCycle.weekly => 'Mingguan',
        BillingCycle.monthly => 'Bulanan',
        BillingCycle.quarterly => '3 Bulanan',
        BillingCycle.yearly => 'Tahunan',
      };

  String get perLabel => switch (this) {
        BillingCycle.weekly => '/mgg',
        BillingCycle.monthly => '/bln',
        BillingCycle.quarterly => '/3 bln',
        BillingCycle.yearly => '/thn',
      };

  /// Faktor konversi ke biaya per bulan.
  double get perMonth => switch (this) {
        BillingCycle.weekly => 52 / 12,
        BillingCycle.monthly => 1,
        BillingCycle.quarterly => 1 / 3,
        BillingCycle.yearly => 1 / 12,
      };

  DateTime nextFrom(DateTime d, int anchorDay) => switch (this) {
        BillingCycle.weekly => d.add(const Duration(days: 7)),
        BillingCycle.monthly => addMonths(d, 1, anchorDay: anchorDay),
        BillingCycle.quarterly => addMonths(d, 3, anchorDay: anchorDay),
        BillingCycle.yearly => addMonths(d, 12, anchorDay: anchorDay),
      };
}

enum Usage { often, sometimes, rarely }

extension UsageX on Usage {
  String get label => switch (this) {
        Usage.often => 'Sering',
        Usage.sometimes => 'Kadang',
        Usage.rarely => 'Jarang',
      };
}

class PricePoint {
  final DateTime date;
  final double amount;
  PricePoint(this.date, this.amount);

  Map<String, dynamic> toJson() =>
      {'date': date.toIso8601String(), 'amount': amount};
  factory PricePoint.fromJson(Map<String, dynamic> j) =>
      PricePoint(DateTime.parse(j['date'] as String), (j['amount'] as num).toDouble());
}

class Subscription {
  final String id;
  String name;
  String category;
  double amount;
  BillingCycle cycle;
  DateTime nextDue;
  int anchorDay;
  String paymentMethod;
  String? cancelUrl;
  String note;
  bool active;
  int color;
  Usage usage;
  int sharedWith; // 1 = dipakai sendiri; >1 = mode keluarga / patungan
  String? catalogKey;
  List<PricePoint> history;
  /// 'IDR' atau 'USD'. Nominal ([amount]) disimpan dalam mata uang ini.
  String currency;
  /// Bila diisi: masa trial gratis berakhir di tanggal ini (tagihan pertama).
  DateTime? trialEnd;

  /// Kurs USD → Rupiah, diatur di Setelan (diisi oleh Repo).
  static double usdRate = 16500;

  Subscription({
    required this.id,
    required this.name,
    required this.category,
    required this.amount,
    required this.cycle,
    required this.nextDue,
    int? anchorDay,
    this.paymentMethod = 'Kartu Kredit',
    this.cancelUrl,
    this.note = '',
    this.active = true,
    this.color = 0xFF0F766E,
    this.usage = Usage.often,
    this.sharedWith = 1,
    this.catalogKey,
    List<PricePoint>? history,
    this.currency = 'IDR',
    this.trialEnd,
  })  : anchorDay = anchorDay ?? nextDue.day,
        history = history ?? [PricePoint(DateTime.now(), amount)];

  bool get isUsd => currency == 'USD';

  /// Nominal per tagihan dalam Rupiah (USD dikonversi dengan kurs Setelan).
  double get amountIdr => isUsd ? amount * usdRate : amount;

  /// Label nominal asli: "Rp54.990" atau "US\$20".
  String get amountLabel => money(amount, currency);

  /// Masih dalam masa trial gratis (belum pernah ditagih).
  bool get onTrial =>
      trialEnd != null && !dateOnly(trialEnd!).isBefore(dateOnly(DateTime.now()));

  double get monthlyCost => amountIdr * cycle.perMonth;
  double get yearlyCost => monthlyCost * 12;
  double get myMonthlyCost => monthlyCost / (sharedWith < 1 ? 1 : sharedWith);

  /// Geser tanggal jatuh tempo ke periode berikutnya bila sudah lewat.
  void rollForward() {
    final today = dateOnly(DateTime.now());
    var guard = 0;
    while (dateOnly(nextDue).isBefore(today) && guard < 1000) {
      nextDue = cycle.nextFrom(nextDue, anchorDay);
      guard++;
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        'amount': amount,
        'cycle': cycle.name,
        'nextDue': nextDue.toIso8601String(),
        'anchorDay': anchorDay,
        'paymentMethod': paymentMethod,
        'cancelUrl': cancelUrl,
        'note': note,
        'active': active,
        'color': color,
        'usage': usage.name,
        'sharedWith': sharedWith,
        'catalogKey': catalogKey,
        'history': history.map((h) => h.toJson()).toList(),
        'currency': currency,
        'trialEnd': trialEnd?.toIso8601String(),
      };

  factory Subscription.fromJson(Map<String, dynamic> j) => Subscription(
        id: j['id'] as String,
        name: j['name'] as String,
        category: (j['category'] as String?) ?? 'Lainnya',
        amount: (j['amount'] as num).toDouble(),
        cycle: BillingCycle.values.firstWhere((c) => c.name == j['cycle'],
            orElse: () => BillingCycle.monthly),
        nextDue: DateTime.parse(j['nextDue'] as String),
        anchorDay: j['anchorDay'] as int?,
        paymentMethod: (j['paymentMethod'] as String?) ?? 'Lainnya',
        cancelUrl: j['cancelUrl'] as String?,
        note: (j['note'] as String?) ?? '',
        active: (j['active'] as bool?) ?? true,
        color: (j['color'] as int?) ?? 0xFF0F766E,
        usage: Usage.values.firstWhere((u) => u.name == j['usage'],
            orElse: () => Usage.often),
        sharedWith: (j['sharedWith'] as int?) ?? 1,
        catalogKey: j['catalogKey'] as String?,
        history: ((j['history'] as List?) ?? [])
            .map((e) => PricePoint.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        currency: (j['currency'] as String?) ?? 'IDR',
        trialEnd: j['trialEnd'] == null ? null : DateTime.tryParse(j['trialEnd'] as String),
      );
}

class PriceAlert {
  final String subId;
  final String name;
  final double oldAmount;
  final double newAmount;
  final DateTime date;
  final String currency;
  bool seen;

  PriceAlert({
    required this.subId,
    required this.name,
    required this.oldAmount,
    required this.newAmount,
    required this.date,
    this.currency = 'IDR',
    this.seen = false,
  });

  String get oldLabel => money(oldAmount, currency);
  String get newLabel => money(newAmount, currency);

  double get percent => oldAmount == 0 ? 0 : (newAmount - oldAmount) / oldAmount * 100;

  Map<String, dynamic> toJson() => {
        'subId': subId,
        'name': name,
        'oldAmount': oldAmount,
        'newAmount': newAmount,
        'date': date.toIso8601String(),
        'seen': seen,
        'currency': currency,
      };

  factory PriceAlert.fromJson(Map<String, dynamic> j) => PriceAlert(
        subId: j['subId'] as String,
        name: j['name'] as String,
        oldAmount: (j['oldAmount'] as num).toDouble(),
        newAmount: (j['newAmount'] as num).toDouble(),
        date: DateTime.parse(j['date'] as String),
        seen: (j['seen'] as bool?) ?? false,
        currency: (j['currency'] as String?) ?? 'IDR',
      );
}

const List<String> kCategories = [
  'Streaming Video',
  'Musik',
  'AI',
  'Cloud',
  'Produktivitas',
  'VPN',
  'Game',
  'Berita & Bacaan',
  'Internet & Pulsa',
  'Kebugaran',
  'Lainnya',
];

const List<String> kPaymentMethods = [
  'Kartu Kredit',
  'Kartu Debit',
  'GoPay',
  'OVO',
  'DANA',
  'ShopeePay',
  'Google Play',
  'App Store',
  'Pulsa',
  'Transfer Bank',
  'Lainnya',
];

/// Kategori yang biasanya berarti "fungsi sama" bila ada lebih dari satu.
const Set<String> kDuplicateProne = {
  'Streaming Video',
  'Musik',
  'AI',
  'Cloud',
  'VPN',
};
