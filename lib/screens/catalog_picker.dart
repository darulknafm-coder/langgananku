import 'package:flutter/material.dart';

import '../data/catalog.dart';
import '../models/subscription.dart';
import '../utils/format.dart';
import '../widgets/common.dart';
import 'edit_screen.dart';

class CatalogPicker extends StatefulWidget {
  const CatalogPicker({super.key});

  @override
  State<CatalogPicker> createState() => _CatalogPickerState();
}

class _CatalogPickerState extends State<CatalogPicker> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final items = kCatalog
        .where((c) =>
            _q.isEmpty ||
            c.name.toLowerCase().contains(_q.toLowerCase()) ||
            c.category.toLowerCase().contains(_q.toLowerCase()))
        .toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Katalog layanan')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        children: [
          TextField(
            autofocus: false,
            decoration: searchDeco('Cari: Netflix, AI, VPN…'),
            onChanged: (v) => setState(() => _q = v),
          ),
          for (final cat in kCategories)
            if (items.any((c) => c.category == cat)) ...[
              SectionTitle(cat),
              AppCard(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(children: [
                  for (final c in items.where((c) => c.category == cat))
                    ListTile(
                      leading: SubAvatar(name: c.name, color: c.color, size: 38),
                      title: Text(c.name),
                      subtitle: Text('± ${rupiah(c.monthly)}/bln'
                          '${c.yearly != null ? ' · ${rupiah(c.yearly!)}/thn' : ''}'),
                      trailing: const Icon(Icons.add),
                      onTap: () => Navigator.of(context).pushReplacement(MaterialPageRoute(
                          builder: (_) => EditScreen(fromCatalog: c))),
                    ),
                ]),
              ),
            ],
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context)
                .pushReplacement(MaterialPageRoute(builder: (_) => const EditScreen())),
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Tidak ada di daftar? Isi manual'),
          ),
        ],
      ),
    );
  }
}

