import 'package:flutter/material.dart';

import '../models/subscription.dart';
import '../services/repository.dart';
import '../utils/format.dart';
import '../widgets/common.dart';
import 'catalog_picker.dart';
import 'detail_screen.dart';
import 'scan_screen.dart';

class DashboardScreen extends StatelessWidget {
  final VoidCallback onSeeAll;
  const DashboardScreen({super.key, required this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    final repo = Repo.instance;
    return ListenableBuilder(
      listenable: repo,
      builder: (context, _) {
        final cs = Theme.of(context).colorScheme;
        final tt = Theme.of(context).textTheme;
        final active = repo.active;
        return Scaffold(
          appBar: AppBar(title: const Text('LanggananKu')),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
            children: [
              // ---- Kartu total ----
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    colors: [cs.primary, Color.lerp(cs.primary, Colors.black, 0.35)!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Total per bulan',
                      style: tt.bodyMedium?.copyWith(color: cs.onPrimary.withAlpha(210))),
                  const SizedBox(height: 4),
                  Text(rupiah(repo.monthlyTotal),
                      style: tt.headlineMedium
                          ?.copyWith(color: cs.onPrimary, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 14),
                  Row(children: [
                    _Stat(label: 'Per tahun', value: rupiah(repo.yearlyTotal), color: cs.onPrimary),
                    _Stat(label: 'Aktif', value: '${active.length} langganan', color: cs.onPrimary),
                  ]),
                ]),
              ),

              // ---- Peringatan kenaikan harga ----
              for (final a in repo.unseenAlerts) ...[
                const SizedBox(height: 12),
                AppCard(
                  color: cs.errorContainer,
                  child: Row(children: [
                    Icon(Icons.trending_up_rounded, color: cs.onErrorContainer),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Harga ${a.name} naik ${a.percent.toStringAsFixed(0)}%: '
                        '${rupiah(a.oldAmount)} → ${rupiah(a.newAmount)}',
                        style: TextStyle(color: cs.onErrorContainer, fontWeight: FontWeight.w600),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Tutup',
                      icon: Icon(Icons.close, color: cs.onErrorContainer),
                      onPressed: () => repo.dismissAlert(a),
                    ),
                  ]),
                ),
              ],

              if (active.isEmpty) ...[
                const SizedBox(height: 24),
                _EmptyState(),
              ] else ...[
                // ---- Jatuh tempo terdekat ----
                SectionTitle('Jatuh tempo terdekat',
                    trailing: TextButton(onPressed: onSeeAll, child: const Text('Lihat semua'))),
                AppCard(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(children: [
                    for (final s in repo.upcoming())
                      SubTile(
                        s: s,
                        onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => DetailScreen(sub: s))),
                      ),
                  ]),
                ),

                // ---- Potensi hemat ----
                if (repo.potentialMonthlySaving > 0) ...[
                  const SizedBox(height: 12),
                  AppCard(
                    color: cs.tertiaryContainer,
                    child: Row(children: [
                      Icon(Icons.savings_outlined, color: cs.onTertiaryContainer),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Potensi hemat ${rupiah(repo.potentialMonthlySaving)}/bulan. '
                          'Lihat saran di tab Hemat.',
                          style: TextStyle(color: cs.onTertiaryContainer),
                        ),
                      ),
                    ]),
                  ),
                ],

                // ---- Per kategori ----
                const SectionTitle('Pengeluaran per kategori'),
                AppCard(
                  child: Column(children: [
                    for (final e in repo.byCategory().entries)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Expanded(child: Text(e.key)),
                            Text(rupiah(e.value),
                                style: const TextStyle(fontWeight: FontWeight.w600)),
                          ]),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: repo.monthlyTotal == 0 ? 0 : e.value / repo.monthlyTotal,
                              minHeight: 8,
                            ),
                          ),
                        ]),
                      ),
                  ]),
                ),
                const SizedBox(height: 8),
                Text(
                  'Total dihitung per bulan; tagihan tahunan dibagi 12, dan langganan '
                  'bersama dibagi jumlah anggota.',
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _Stat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(color: color.withAlpha(190), fontSize: 12)),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w700)),
        ]),
      );
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AppCard(
      child: Column(children: [
        Icon(Icons.inbox_outlined, size: 48, color: cs.primary),
        const SizedBox(height: 8),
        const Text('Belum ada langganan',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        const SizedBox(height: 4),
        Text('Pindai SMS/email nota atau pilih dari katalog layanan populer.',
            textAlign: TextAlign.center, style: TextStyle(color: cs.onSurfaceVariant)),
        const SizedBox(height: 16),
        Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center, children: [
          FilledButton.icon(
            onPressed: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const ScanScreen())),
            icon: const Icon(Icons.document_scanner_outlined),
            label: const Text('Pindai'),
          ),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const CatalogPicker())),
            icon: const Icon(Icons.grid_view_rounded),
            label: const Text('Katalog'),
          ),
        ]),
      ]),
    );
  }
}

/// Dipakai layar lain untuk label singkat siklus.
String cycleText(Subscription s) => '${rupiah(s.amount)}${s.cycle.perLabel}';
