import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/catalog.dart';
import '../models/subscription.dart';
import '../services/repository.dart';
import '../theme/app_theme.dart';
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
    final done = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Sudah dibatalkan?', style: TextStyle(fontWeight: FontWeight.w800)),
        content: Text('Tandai ${sub.name} sebagai nonaktif agar tidak dihitung lagi.',
            style: const TextStyle(color: AppColors.muted)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Belum')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sudah, tandai')),
        ],
      ),
    );
    if (done == true) {
      await Repo.instance.setActive(sub, false);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Hemat ${rupiah(sub.yearlyCost)} per tahun. Mantap!')));
      }
    }
  }

  Future<void> _delete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Hapus ${sub.name}?', style: const TextStyle(fontWeight: FontWeight.w800)),
        content: const Text('Data dan riwayat harga akan dihapus dari HP ini.',
            style: TextStyle(color: AppColors.muted)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.coral, foregroundColor: AppColors.onLime),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok == true) {
      final repo = Repo.instance;
      final messenger = ScaffoldMessenger.of(context);
      final index = repo.subs.indexWhere((x) => x.id == sub.id);
      final removedAlerts = repo.alerts.where((a) => a.subId == sub.id).toList();
      await repo.remove(sub);
      if (context.mounted) Navigator.of(context).pop();
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text('${sub.name} dihapus.'),
          duration: const Duration(seconds: 6),
          action: SnackBarAction(
            label: 'Urungkan',
            onPressed: () => repo.restore(sub, removedAlerts, index),
          ),
        ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = Repo.instance;
    return ListenableBuilder(
      listenable: repo,
      builder: (context, _) {
        final saving = repo.annualSaving(sub);
        final history = sub.history.reversed.toList();

        Widget info(String label, String value, {Color? color}) => Expanded(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.line),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 12.5)),
                  const SizedBox(height: 4),
                  Text(value,
                      maxLines: 2,
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14.5,
                          color: color ?? AppColors.text,
                          fontFeatures: kTabular)),
                ]),
              ),
            );

        return Scaffold(
          appBar: AppBar(
            actions: [
              IconButton(
                tooltip: 'Edit',
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => Navigator.of(context)
                    .push(MaterialPageRoute(builder: (_) => EditScreen(existing: sub))),
              ),
              IconButton(
                  tooltip: 'Hapus',
                  icon: const Icon(Icons.delete_outline_rounded),
                  onPressed: () => _delete(context)),
              const SizedBox(width: 4),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
            children: [
              // ---------- Hero ----------
              Center(child: SubAvatar(name: sub.name, color: sub.color, size: 76)),
              const SizedBox(height: 14),
              Center(
                child: Text(sub.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              ),
              const SizedBox(height: 6),
              Center(
                child: Text.rich(
                  TextSpan(children: [
                    TextSpan(
                        text: sub.amountLabel,
                        style: const TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1,
                            fontFeatures: kTabular)),
                    TextSpan(
                        text: ' ${sub.cycle.perLabel}',
                        style: const TextStyle(fontSize: 16, color: AppColors.muted)),
                  ]),
                ),
              ),
              if (sub.isUsd)
                Center(
                  child: Text('≈ ${rupiah(sub.amountIdr)} · kurs ${rupiah(Subscription.usdRate)}/US\$',
                      style: const TextStyle(color: AppColors.muted, fontSize: 13)),
                ),
              const SizedBox(height: 12),
              Wrap(alignment: WrapAlignment.center, spacing: 8, runSpacing: 8, children: [
                if (sub.active) Pill.forSub(sub)
                else const Pill('Nonaktif', fg: AppColors.faint, bg: AppColors.surface3),
                Pill(sub.category, fg: AppColors.text, bg: AppColors.surface3),
                if (sub.sharedWith > 1)
                  Pill('Dibagi ${sub.sharedWith} orang',
                      fg: AppColors.sky, bg: AppColors.sky.withAlpha(30), icon: Icons.group_rounded),
              ]),
              const SizedBox(height: 24),

              // ---------- Info ----------
              Row(children: [
                info(sub.onTrial ? 'Trial berakhir' : 'Tagihan berikutnya', sub.active ? tanggal(sub.nextDue) : '—'),
                const SizedBox(width: 10),
                info('Bayar via', sub.paymentMethod),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                info('Setara per bulan',
                    sub.sharedWith > 1 ? '${rupiah(sub.myMonthlyCost)} (bagian Anda)' : rupiah(sub.monthlyCost)),
                const SizedBox(width: 10),
                info('Setara per tahun', rupiah(sub.yearlyCost)),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                info('Frekuensi pemakaian', sub.usage.label,
                    color: sub.usage == Usage.rarely ? AppColors.amber : null),
                const SizedBox(width: 10),
                info('Siklus', sub.cycle.label),
              ]),
              if (sub.note.isNotEmpty) ...[
                const SizedBox(height: 10),
                Row(children: [info('Catatan', sub.note)]),
              ],

              if (saving > 0) ...[
                const SizedBox(height: 14),
                AppCard(
                  color: AppColors.limeDeep,
                  borderColor: AppColors.lime.withAlpha(60),
                  child: Row(children: [
                    const Icon(Icons.savings_rounded, color: AppColors.lime),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Pindah ke paket tahunan bisa hemat sekitar ${rupiah(saving)} per tahun.',
                        style: const TextStyle(color: AppColors.lime, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ]),
                ),
              ],

              // ---------- Riwayat harga ----------
              const SectionTitle('Riwayat harga'),
              AppCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Column(children: [
                  for (var i = 0; i < history.length; i++) ...[
                    if (i > 0) const Divider(),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(children: [
                        Expanded(
                            child: Text(tanggal(history[i].date),
                                style: const TextStyle(color: AppColors.muted))),
                        if (i + 1 < history.length &&
                            history[i].amount != history[i + 1].amount) ...[
                          _ChangeBadge(
                              from: history[i + 1].amount, to: history[i].amount),
                          const SizedBox(width: 10),
                        ],
                        Text(money(history[i].amount, sub.currency),
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontFeatures: kTabular)),
                      ]),
                    ),
                  ],
                ]),
              ),
              const SizedBox(height: 28),

              // ---------- Aksi ----------
              if (sub.active) ...[
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.coral,
                      side: BorderSide(color: AppColors.coral.withAlpha(140)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: () => _cancel(context),
                    icon: const Icon(Icons.block_rounded),
                    label: const Text('Batalkan langganan',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Membuka halaman pengelolaan langganan resmi layanan ini.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.faint, fontSize: 12.5),
                ),
              ] else
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => repo.setActive(sub, true),
                    icon: const Icon(Icons.restart_alt_rounded),
                    label: const Text('Aktifkan lagi'),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ChangeBadge extends StatelessWidget {
  final double from;
  final double to;
  const _ChangeBadge({required this.from, required this.to});

  @override
  Widget build(BuildContext context) {
    final up = to > from;
    final pct = from == 0 ? 0 : ((to - from) / from * 100).abs().round();
    return Pill('${up ? '+' : '−'}$pct%',
        fg: up ? AppColors.coral : AppColors.lime,
        bg: up ? AppColors.coralDeep : AppColors.limeDeep,
        icon: up ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded);
  }
}
