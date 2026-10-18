import 'package:flutter/material.dart';

import '../services/repository.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/common.dart';
import 'detail_screen.dart';

class SubscriptionsScreen extends StatefulWidget {
  const SubscriptionsScreen({super.key});

  @override
  State<SubscriptionsScreen> createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends State<SubscriptionsScreen> {
  bool _showActive = true;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final repo = Repo.instance;
    return ListenableBuilder(
      listenable: repo,
      builder: (context, _) {
        final activeCount = repo.subs.where((s) => s.active).length;
        final list = repo.subs
            .where((s) => s.active == _showActive)
            .where((s) => _query.isEmpty || s.name.toLowerCase().contains(_query.toLowerCase()))
            .toList()
          ..sort((a, b) => a.nextDue.compareTo(b.nextDue));
        final sum = list.fold<double>(0, (a, s) => a + s.myMonthlyCost);

        Widget tab(String label, bool value, int n) {
          final on = _showActive == value;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _showActive = value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: on ? AppColors.lime : Colors.transparent,
                  borderRadius: BorderRadius.circular(99),
                ),
                alignment: Alignment.center,
                child: Text('$label  $n',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: on ? AppColors.onLime : AppColors.muted)),
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(title: const Text('Langganan')),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 110),
            children: [
              TextField(
                decoration: searchDeco('Cari langganan'),
                onChanged: (v) => setState(() => _query = v),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: AppColors.line),
                ),
                child: Row(children: [
                  tab('Aktif', true, activeCount),
                  tab('Nonaktif', false, repo.subs.length - activeCount),
                ]),
              ),
              const SizedBox(height: 18),
              if (list.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 2, bottom: 10),
                  child: Text(
                    _showActive
                        ? '${list.length} layanan · ${rupiah(sum)}/bln'
                        : '${list.length} layanan dibatalkan · hemat ${rupiah(sum * 12)}/thn',
                    style: const TextStyle(color: AppColors.muted, fontSize: 13),
                  ),
                ),
              if (list.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 48),
                  child: Column(children: [
                    Icon(_showActive ? Icons.layers_outlined : Icons.check_circle_outline_rounded,
                        size: 40, color: AppColors.faint),
                    const SizedBox(height: 12),
                    Text(
                      _showActive
                          ? 'Belum ada langganan aktif.\nKetuk "Tambah" untuk mulai.'
                          : 'Belum ada langganan yang dibatalkan.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.muted),
                    ),
                  ]),
                )
              else
                TileGroup(children: [
                  for (final s in list)
                    SubTile(
                      s: s,
                      onTap: () => Navigator.of(context)
                          .push(MaterialPageRoute(builder: (_) => DetailScreen(sub: s))),
                    ),
                ]),
            ],
          ),
        );
      },
    );
  }
}
