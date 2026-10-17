import 'package:flutter/material.dart';

import '../services/repository.dart';
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
        final list = repo.subs
            .where((s) => s.active == _showActive)
            .where((s) => _query.isEmpty || s.name.toLowerCase().contains(_query.toLowerCase()))
            .toList()
          ..sort((a, b) => a.nextDue.compareTo(b.nextDue));
        return Scaffold(
          appBar: AppBar(title: const Text('Langganan')),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
            children: [
              TextField(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Cari langganan',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
              const SizedBox(height: 12),
              SegmentedButton<bool>(
                segments: [
                  ButtonSegment(
                      value: true,
                      label: Text('Aktif (${repo.subs.where((s) => s.active).length})')),
                  ButtonSegment(
                      value: false,
                      label: Text('Nonaktif (${repo.subs.where((s) => !s.active).length})')),
                ],
                selected: {_showActive},
                onSelectionChanged: (v) => setState(() => _showActive = v.first),
              ),
              const SizedBox(height: 12),
              if (list.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    _showActive
                        ? 'Belum ada langganan aktif. Ketuk "Tambah".'
                        : 'Belum ada langganan yang dibatalkan.',
                    textAlign: TextAlign.center,
                  ),
                )
              else
                AppCard(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(children: [
                    for (final s in list)
                      SubTile(
                        s: s,
                        onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => DetailScreen(sub: s))),
                      ),
                  ]),
                ),
            ],
          ),
        );
      },
    );
  }
}
