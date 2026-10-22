import 'package:flutter/material.dart';

import '../data/catalog.dart';
import '../models/subscription.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/common.dart';
import 'edit_screen.dart';
import 'scan_screen.dart';

/// Langkah 1 menambah langganan: pilih layanannya.
class CatalogPicker extends StatefulWidget {
  const CatalogPicker({super.key});

  @override
  State<CatalogPicker> createState() => _CatalogPickerState();
}

const _popularKeys = [
  'netflix', 'spotify', 'youtube', 'disney', 'chatgpt', 'googleone', 'canva', 'indihome',
];

class _CatalogPickerState extends State<CatalogPicker> {
  String _q = '';

  void _open(CatalogItem? c) => Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => EditScreen(fromCatalog: c)));

  @override
  Widget build(BuildContext context) {
    final q = _q.trim().toLowerCase();
    final items = kCatalog
        .where((c) =>
            q.isEmpty || c.name.toLowerCase().contains(q) || c.category.toLowerCase().contains(q))
        .toList();
    final popular = [for (final k in _popularKeys) catalogByKey(k)].whereType<CatalogItem>();

    return Scaffold(
      appBar: AppBar(title: const Text('Tambah langganan')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        children: [
          const Text('Langganan apa yang mau dicatat?',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, height: 1.25)),
          const SizedBox(height: 6),
          Text('Pilih layanannya, lalu isi harga dan tanggal bayar.',
              style: TextStyle(color: AppColors.muted)),
          const SizedBox(height: 16),
          TextField(
            decoration: searchDeco('Cari: Netflix, Spotify, wifi…'),
            onChanged: (v) => setState(() => _q = v),
          ),

          if (q.isEmpty) ...[
            const SectionTitle('Paling sering dipilih'),
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 8,
              childAspectRatio: 0.78,
              children: [
                for (final c in popular)
                  InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _open(c),
                    child: Column(children: [
                      const SizedBox(height: 4),
                      SubAvatar(logoKey: c.key, name: c.name, color: c.color, size: 52),
                      const SizedBox(height: 8),
                      Text(c.name.replaceAll(RegExp(r' (Premium|Plus|Pro|Hotstar|Platinum)\b'), ''),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                    ]),
                  ),
              ],
            ),
          ],

          // ---------- Cara lain ----------
          const SizedBox(height: 18),
          _WayCard(
            icon: Icons.edit_rounded,
            title: q.isEmpty ? 'Tidak ada di daftar? Tulis sendiri' : 'Tulis sendiri "${_q.trim()}"',
            subtitle: 'Untuk wifi, gym, cicilan, atau layanan lain',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => EditScreen(
                    fromCatalog: null,
                    initialName: q.isEmpty ? null : _q.trim()))),
          ),
          const SizedBox(height: 10),
          _WayCard(
            icon: Icons.content_paste_rounded,
            title: 'Punya email atau SMS tagihan?',
            subtitle: 'Tempel teksnya, kami isikan otomatis',
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const ScanScreen())),
          ),

          // ---------- Semua layanan ----------
          for (final cat in kCategories)
            if (items.any((c) => c.category == cat)) ...[
              SectionTitle(cat),
              TileGroup(children: [
                for (final c in items.where((c) => c.category == cat))
                  ListTile(
                    leading: SubAvatar(logoKey: c.key, name: c.name, color: c.color, size: 38),
                    title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('Mulai ± ${money(c.monthly, c.currency)} per bulan'),
                    trailing: Icon(Icons.chevron_right_rounded, color: AppColors.faint),
                    onTap: () => _open(c),
                  ),
              ]),
            ],
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Text('Tidak ditemukan. Pakai "Tulis sendiri" di atas.',
                  textAlign: TextAlign.center, style: TextStyle(color: AppColors.muted)),
            ),
        ],
      ),
    );
  }
}

class _WayCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _WayCard(
      {required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Row(children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
              color: AppColors.limeDeep, borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: AppColors.accentText, size: 21),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 2),
            Text(subtitle, style: TextStyle(color: AppColors.muted, fontSize: 12.5)),
          ]),
        ),
        Icon(Icons.chevron_right_rounded, color: AppColors.faint),
      ]),
    );
  }
}
