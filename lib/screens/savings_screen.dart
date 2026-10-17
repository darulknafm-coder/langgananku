import 'package:flutter/material.dart';

import '../data/catalog.dart';
import '../models/subscription.dart';
import '../services/repository.dart';
import '../utils/format.dart';
import '../widgets/common.dart';
import 'detail_screen.dart';

/// Simulasi skenario, deteksi duplikasi, dan rekomendasi hemat.
class SavingsScreen extends StatefulWidget {
  const SavingsScreen({super.key});

  @override
  State<SavingsScreen> createState() => _SavingsScreenState();
}

class _SavingsScreenState extends State<SavingsScreen> {
  final Set<String> _stopIds = {};
  double _months = 6;

  @override
  Widget build(BuildContext context) {
    final repo = Repo.instance;
    return ListenableBuilder(
      listenable: repo,
      builder: (context, _) {
        final cs = Theme.of(context).colorScheme;
        final tt = Theme.of(context).textTheme;
        final active = repo.active..sort((a, b) => b.myMonthlyCost.compareTo(a.myMonthlyCost));
        _stopIds.removeWhere((id) => !active.any((s) => s.id == id));
        final stopMonthly = active
            .where((s) => _stopIds.contains(s.id))
            .fold<double>(0, (a, s) => a + s.myMonthlyCost);
        final simTotal = stopMonthly * _months;

        final rare = active.where((s) => s.usage == Usage.rarely).toList();
        final annual = active.where((s) => repo.annualSaving(s) > 0).toList();
        final dups = repo.duplicates();
        final shared = active.where((s) => s.sharedWith > 1).toList();

        void open(Subscription s) => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => DetailScreen(sub: s)));

        return Scaffold(
          appBar: AppBar(title: const Text('Hemat')),
          body: active.isEmpty
              ? const Center(
                  child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('Tambahkan langganan dulu untuk melihat simulasi dan saran hemat.',
                      textAlign: TextAlign.center),
                ))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
                  children: [
                    // ---------- Simulasi ----------
                    const SectionTitle('Simulasi: berapa hemat kalau berhenti?'),
                    AppCard(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Pilih langganan yang ingin dihentikan:',
                            style: TextStyle(color: cs.onSurfaceVariant)),
                        const SizedBox(height: 8),
                        Wrap(spacing: 8, runSpacing: 8, children: [
                          for (final s in active)
                            FilterChip(
                              label: Text(s.name),
                              selected: _stopIds.contains(s.id),
                              onSelected: (v) => setState(
                                  () => v ? _stopIds.add(s.id) : _stopIds.remove(s.id)),
                            ),
                        ]),
                        const SizedBox(height: 12),
                        Text('Selama ${_months.round()} bulan'),
                        Slider(
                          value: _months,
                          min: 1,
                          max: 24,
                          divisions: 23,
                          label: '${_months.round()} bln',
                          onChanged: (v) => setState(() => _months = v),
                        ),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                              color: cs.primaryContainer,
                              borderRadius: BorderRadius.circular(12)),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('Uang yang bisa dihemat',
                                style: TextStyle(color: cs.onPrimaryContainer)),
                            Text(rupiah(simTotal),
                                style: tt.headlineSmall?.copyWith(
                                    color: cs.onPrimaryContainer, fontWeight: FontWeight.w800)),
                            if (stopMonthly > 0)
                              Text(
                                'Pengeluaran bulanan turun dari ${rupiah(repo.monthlyTotal)} '
                                'menjadi ${rupiah(repo.monthlyTotal - stopMonthly)}.',
                                style: TextStyle(color: cs.onPrimaryContainer),
                              ),
                          ]),
                        ),
                      ]),
                    ),

                    // ---------- Jarang dipakai ----------
                    if (rare.isNotEmpty) ...[
                      const SectionTitle('Jarang dipakai — pertimbangkan berhenti'),
                      AppCard(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Column(children: [
                          for (final s in rare)
                            ListTile(
                              leading: SubAvatar(name: s.name, color: s.color, size: 38),
                              title: Text(s.name),
                              subtitle: Text('Hemat ${rupiah(s.myMonthlyCost * 12)}/tahun'),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => open(s),
                            ),
                        ]),
                      ),
                    ],

                    // ---------- Duplikasi ----------
                    if (dups.isNotEmpty) ...[
                      const SectionTitle('Fungsi sama (duplikasi)'),
                      for (final e in dups.entries) ...[
                        AppCard(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('${e.value.length} layanan ${e.key}',
                                style: const TextStyle(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 4),
                            Text(
                              '${e.value.map((s) => s.name).join(', ')} — total '
                              '${rupiah(e.value.fold<double>(0, (a, s) => a + s.myMonthlyCost))}/bln. '
                              'Apakah semuanya benar-benar dipakai?',
                              style: TextStyle(color: cs.onSurfaceVariant),
                            ),
                          ]),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ],

                    // ---------- Paket tahunan ----------
                    if (annual.isNotEmpty) ...[
                      const SectionTitle('Lebih murah dengan paket tahunan'),
                      AppCard(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Column(children: [
                          for (final s in annual)
                            ListTile(
                              leading: SubAvatar(name: s.name, color: s.color, size: 38),
                              title: Text(s.name),
                              subtitle: Text(
                                  '${rupiah(s.yearlyCost)}/thn → ${rupiah(catalogByKey(s.catalogKey)!.yearly!)}/thn'),
                              trailing: Text('-${rupiah(repo.annualSaving(s))}',
                                  style: TextStyle(
                                      color: cs.primary, fontWeight: FontWeight.w700)),
                              onTap: () => open(s),
                            ),
                        ]),
                      ),
                    ],

                    // ---------- Mode keluarga ----------
                    if (shared.isNotEmpty) ...[
                      const SectionTitle('Langganan bersama (mode keluarga)'),
                      AppCard(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Column(children: [
                          for (final s in shared)
                            ListTile(
                              leading: SubAvatar(name: s.name, color: s.color, size: 38),
                              title: Text(s.name),
                              subtitle: Text(
                                  '${rupiah(s.monthlyCost)}/bln dibagi ${s.sharedWith} orang'),
                              trailing: Text('${rupiah(s.myMonthlyCost)}/org',
                                  style: const TextStyle(fontWeight: FontWeight.w700)),
                            ),
                        ]),
                      ),
                    ],

                    if (rare.isEmpty && dups.isEmpty && annual.isEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Tip: tandai frekuensi pemakaian tiap langganan (Sering/Kadang/Jarang) '
                        'di menu Edit agar saran hemat lebih akurat.',
                        style: TextStyle(color: cs.onSurfaceVariant),
                      ),
                    ],
                  ],
                ),
        );
      },
    );
  }
}
