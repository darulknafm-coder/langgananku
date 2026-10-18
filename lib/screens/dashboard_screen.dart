import 'package:flutter/material.dart';

import '../models/subscription.dart';
import '../services/repository.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/common.dart';
import 'catalog_picker.dart';
import 'detail_screen.dart';
import 'scan_screen.dart';

String _salam() {
  final h = DateTime.now().hour;
  if (h < 11) return 'Selamat pagi';
  if (h < 15) return 'Selamat siang';
  if (h < 18) return 'Selamat sore';
  return 'Selamat malam';
}

class DashboardScreen extends StatelessWidget {
  final VoidCallback onSeeAll;
  final VoidCallback onOpenSavings;
  const DashboardScreen({super.key, required this.onSeeAll, required this.onOpenSavings});

  void _open(BuildContext context, Subscription s) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => DetailScreen(sub: s)));

  @override
  Widget build(BuildContext context) {
    final repo = Repo.instance;
    return ListenableBuilder(
      listenable: repo,
      builder: (context, _) {
        final active = repo.active;
        final alerts = repo.unseenAlerts;
        final saving = repo.potentialMonthlySaving;
        return Scaffold(
          body: SafeArea(
            bottom: false,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
              children: [
                // ---------- Header ----------
                Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(_salam(),
                          style: const TextStyle(color: AppColors.muted, fontSize: 14)),
                      const SizedBox(height: 2),
                      const Text('LanggananKu',
                          style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.4)),
                    ]),
                  ),
                  _Bell(count: alerts.length),
                ]),
                const SizedBox(height: 20),

                // ---------- Kartu total ----------
                _TotalCard(
                  monthly: repo.monthlyTotal,
                  yearly: repo.yearlyTotal,
                  count: active.length,
                ),

                // ---------- Peringatan harga ----------
                for (final a in alerts) ...[
                  const SizedBox(height: 12),
                  AppCard(
                    color: AppColors.coralDeep,
                    borderColor: AppColors.coral.withAlpha(70),
                    padding: const EdgeInsets.fromLTRB(16, 12, 6, 12),
                    child: Row(children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                            color: AppColors.coral.withAlpha(40),
                            borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.trending_up_rounded,
                            color: AppColors.coral, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Harga ${a.name} naik ${a.percent.toStringAsFixed(0)}%',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, color: AppColors.text)),
                          const SizedBox(height: 2),
                          Text('${rupiah(a.oldAmount)} → ${rupiah(a.newAmount)}',
                              style: const TextStyle(
                                  color: Color(0xFFFFB4AB),
                                  fontSize: 13,
                                  fontFeatures: kTabular)),
                        ]),
                      ),
                      IconButton(
                        tooltip: 'Tutup',
                        icon: const Icon(Icons.close_rounded, color: AppColors.muted, size: 20),
                        onPressed: () => repo.dismissAlert(a),
                      ),
                    ]),
                  ),
                ],

                if (active.isEmpty) ...[
                  const SizedBox(height: 20),
                  const _EmptyState(),
                ] else ...[
                  // ---------- Segera ditagih ----------
                  SectionTitle('Segera ditagih',
                      trailing: TextButton(onPressed: onSeeAll, child: const Text('Lihat semua'))),
                  SizedBox(
                    height: 156,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      clipBehavior: Clip.none,
                      itemCount: repo.upcoming(8).length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, i) {
                        final s = repo.upcoming(8)[i];
                        return _UpcomingCard(s: s, onTap: () => _open(context, s));
                      },
                    ),
                  ),

                  // ---------- Potensi hemat ----------
                  if (saving > 0) ...[
                    const SizedBox(height: 16),
                    Material(
                      color: AppColors.lime,
                      borderRadius: BorderRadius.circular(20),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: onOpenSavings,
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Row(children: [
                            Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Potensi hemat',
                                        style: TextStyle(
                                            color: AppColors.onLime,
                                            fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 2),
                                    Text('${rupiah(saving)}/bln',
                                        style: const TextStyle(
                                            color: AppColors.onLime,
                                            fontSize: 24,
                                            fontWeight: FontWeight.w800,
                                            fontFeatures: kTabular)),
                                    const SizedBox(height: 2),
                                    const Text(
                                        'Dari langganan jarang dipakai, duplikat, dan paket tahunan',
                                        style: TextStyle(
                                            color: AppColors.onLime, fontSize: 12.5)),
                                  ]),
                            ),
                            Container(
                              width: 44,
                              height: 44,
                              decoration: const BoxDecoration(
                                  color: AppColors.onLime, shape: BoxShape.circle),
                              child: const Icon(Icons.arrow_forward_rounded,
                                  color: AppColors.lime),
                            ),
                          ]),
                        ),
                      ),
                    ),
                  ],

                  // ---------- Komposisi ----------
                  const SectionTitle('Komposisi pengeluaran'),
                  _CategoryCard(data: repo.byCategory(), total: repo.monthlyTotal),
                  const SizedBox(height: 12),
                  const Text(
                    'Tagihan tahunan dihitung per bulan; langganan bersama dibagi jumlah anggota.',
                    style: TextStyle(color: AppColors.faint, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Bell extends StatelessWidget {
  final int count;
  const _Bell({required this.count});

  @override
  Widget build(BuildContext context) {
    return Stack(clipBehavior: Clip.none, children: [
      Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.line),
        ),
        child: const Icon(Icons.notifications_none_rounded, color: AppColors.text),
      ),
      if (count > 0)
        Positioned(
          right: 2,
          top: 2,
          child: Container(
            width: 18,
            height: 18,
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: AppColors.coral, shape: BoxShape.circle),
            child: Text('$count',
                style: const TextStyle(
                    fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.onLime)),
          ),
        ),
    ]);
  }
}

class _TotalCard extends StatelessWidget {
  final double monthly;
  final double yearly;
  final int count;
  const _TotalCard({required this.monthly, required this.yearly, required this.count});

  @override
  Widget build(BuildContext context) {
    Widget stat(String label, String value) => Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 12.5)),
            const SizedBox(height: 3),
            Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 15, fontFeatures: kTabular)),
          ]),
        );

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.line),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1C2114), AppColors.surface, AppColors.surface],
          stops: [0, 0.55, 1],
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(color: AppColors.lime, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          const Text('Pengeluaran per bulan',
              style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 10),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(rupiah(monthly),
              style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.2,
                  height: 1.1,
                  fontFeatures: kTabular)),
        ),
        const SizedBox(height: 18),
        Container(height: 1, color: AppColors.line),
        const SizedBox(height: 14),
        Row(children: [
          stat('Per tahun', rupiah(yearly)),
          stat('Langganan aktif', '$count layanan'),
        ]),
      ]),
    );
  }
}

class _UpcomingCard extends StatelessWidget {
  final Subscription s;
  final VoidCallback onTap;
  const _UpcomingCard({required this.s, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            SubAvatar(name: s.name, color: s.color, size: 38),
            const Spacer(),
          ]),
          const Spacer(),
          Text(s.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
          const SizedBox(height: 2),
          Text(rupiah(s.amount),
              style: const TextStyle(
                  color: AppColors.muted, fontSize: 13, fontFeatures: kTabular)),
          const SizedBox(height: 8),
          Pill.due(s.nextDue),
        ]),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final Map<String, double> data;
  final double total;
  const _CategoryCard({required this.data, required this.total});

  @override
  Widget build(BuildContext context) {
    final entries = data.entries.toList();
    final colors = [for (var i = 0; i < entries.length; i++) AppColors.chart[i % AppColors.chart.length]];
    return AppCard(
      child: Column(children: [
        DonutChart(
          values: [for (final e in entries) e.value],
          colors: colors,
          size: 168,
          stroke: 18,
          center: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('${entries.length}',
                style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800)),
            const Text('kategori', style: TextStyle(color: AppColors.muted, fontSize: 12.5)),
          ]),
        ),
        const SizedBox(height: 20),
        for (var i = 0; i < entries.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: Row(children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: colors[i], borderRadius: BorderRadius.circular(3)),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(entries[i].key, style: const TextStyle(fontSize: 14))),
              Text('${total == 0 ? 0 : (entries[i].value / total * 100).round()}%',
                  style: const TextStyle(color: AppColors.muted, fontSize: 13, fontFeatures: kTabular)),
              const SizedBox(width: 12),
              SizedBox(
                width: 96,
                child: Text(rupiah(entries[i].value),
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontFeatures: kTabular)),
              ),
            ]),
          ),
      ]),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(24),
      child: Column(children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
              color: AppColors.limeDeep, borderRadius: BorderRadius.circular(20)),
          child: const Icon(Icons.layers_rounded, size: 30, color: AppColors.lime),
        ),
        const SizedBox(height: 16),
        const Text('Belum ada langganan',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        const SizedBox(height: 6),
        const Text('Pindai SMS/email nota atau pilih dari katalog layanan populer.',
            textAlign: TextAlign.center, style: TextStyle(color: AppColors.muted)),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const ScanScreen())),
            icon: const Icon(Icons.document_scanner_rounded),
            label: const Text('Pindai tagihan'),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const CatalogPicker())),
            icon: const Icon(Icons.grid_view_rounded),
            label: const Text('Pilih dari katalog'),
          ),
        ),
      ]),
    );
  }
}

/// Dipakai layar lain untuk label singkat siklus.
String cycleText(Subscription s) => '${rupiah(s.amount)}${s.cycle.perLabel}';
