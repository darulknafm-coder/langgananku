import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/catalog.dart';
import '../models/subscription.dart';
import '../services/repository.dart';
import '../utils/format.dart';
import '../widgets/common.dart';
import 'edit_screen.dart';

class DetailScreen extends StatelessWidget {
  final Subscription sub;
  const DetailScreen({super.key, required this.sub});

  Future<void> _cancel(BuildContext context) async {
    final url = (sub.cancelUrl == null || sub.cancelUrl!.isEmpty)
        ? (Theme.of(context).platform == TargetPlatform.iOS ? kAppleSubs : kGooglePlaySubs)
        : sub.cancelUrl!;
    var ok = false;
    try {
      ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {
      ok = false;
    }
    if (!context.mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Tidak bisa membuka $url')));
      return;
    }
    // Setelah kembali dari halaman pembatalan, tanyakan hasilnya.
    final done = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sudah dibatalkan?'),
        content: Text('Tandai ${sub.name} sebagai nonaktif agar tidak dihitung lagi.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Belum')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sudah, tandai')),
        ],
      ),
    );
    if (done == true) {
      await Repo.instance.setActive(sub, false);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Hemat ${rupiah(sub.yearlyCost)} per tahun. Mantap!')));
      }
    }
  }

  Future<void> _delete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Hapus ${sub.name}?'),
        content: const Text('Data dan riwayat harga akan dihapus dari HP ini.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Hapus')),
        ],
      ),
    );
    if (ok == true) {
      await Repo.instance.remove(sub);
      if (context.mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = Repo.instance;
    return ListenableBuilder(
      listenable: repo,
      builder: (context, _) {
        final cs = Theme.of(context).colorScheme;
        final tt = Theme.of(context).textTheme;
        final saving = repo.annualSaving(sub);
        Widget row(String k, String v) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(children: [
                Expanded(child: Text(k, style: TextStyle(color: cs.onSurfaceVariant))),
                Flexible(
                    child: Text(v,
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontWeight: FontWeight.w600))),
              ]),
            );

        return Scaffold(
          appBar: AppBar(
            title: Text(sub.name),
            actions: [
              IconButton(
                tooltip: 'Edit',
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => Navigator.of(context)
                    .push(MaterialPageRoute(builder: (_) => EditScreen(existing: sub))),
              ),
              IconButton(
                  tooltip: 'Hapus',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _delete(context)),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(children: [
                SubAvatar(name: sub.name, color: sub.color, size: 56),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(rupiah(sub.amount),
                        style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                    Text('${sub.cycle.label} · ${sub.category}',
                        style: TextStyle(color: cs.onSurfaceVariant)),
                  ]),
                ),
              ]),
              const SizedBox(height: 16),
              AppCard(
                child: Column(children: [
                  row('Status', sub.active ? 'Aktif' : 'Nonaktif'),
                  if (sub.active)
                    row('Jatuh tempo', '${tanggal(sub.nextDue)} (${sisaHari(sub.nextDue)})'),
                  row('Metode bayar', sub.paymentMethod),
                  row('Setara per bulan', rupiah(sub.monthlyCost)),
                  row('Setara per tahun', rupiah(sub.yearlyCost)),
                  if (sub.sharedWith > 1)
                    row('Bagian saya (÷${sub.sharedWith})', '${rupiah(sub.myMonthlyCost)}/bln'),
                  row('Frekuensi pemakaian', sub.usage.label),
                  if (sub.note.isNotEmpty) row('Catatan', sub.note),
                ]),
              ),
              if (saving > 0) ...[
                const SizedBox(height: 12),
                AppCard(
                  color: cs.tertiaryContainer,
                  child: Text(
                    'Pindah ke paket tahunan bisa hemat sekitar ${rupiah(saving)} per tahun.',
                    style: TextStyle(color: cs.onTertiaryContainer),
                  ),
                ),
              ],
              const SectionTitle('Riwayat harga'),
              AppCard(
                child: Column(children: [
                  for (final h in sub.history.reversed)
                    row(tanggal(h.date), rupiah(h.amount)),
                ]),
              ),
              const SizedBox(height: 24),
              if (sub.active)
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                      backgroundColor: cs.error, foregroundColor: cs.onError),
                  onPressed: () => _cancel(context),
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('Batalkan langganan'),
                  ),
                )
              else
                OutlinedButton.icon(
                  onPressed: () => repo.setActive(sub, true),
                  icon: const Icon(Icons.restart_alt),
                  label: const Text('Aktifkan lagi'),
                ),
              const SizedBox(height: 8),
              Text(
                'Tombol batalkan membuka halaman pengelolaan langganan resmi layanan tersebut.',
                textAlign: TextAlign.center,
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        );
      },
    );
  }
}
