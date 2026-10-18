import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/catalog.dart';
import '../models/subscription.dart';
import '../services/promo_service.dart';
import '../services/repository.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/common.dart';
import 'edit_screen.dart';

Future<void> openOfficial(BuildContext context, String url) async {
  var ok = false;
  try {
    ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  } catch (_) {}
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Tidak bisa membuka $url')));
  }
}

/// Daftar paket resmi & promo tiap layanan populer.
class PromoScreen extends StatefulWidget {
  const PromoScreen({super.key});

  @override
  State<PromoScreen> createState() => _PromoScreenState();
}

class _PromoScreenState extends State<PromoScreen> {
  bool _onlyOffers = false;

  @override
  Widget build(BuildContext context) {
    final promo = PromoService.instance;
    return ListenableBuilder(
      listenable: Listenable.merge([promo, Repo.instance]),
      builder: (context, _) {
        final list = promo.services
            .where((s) => catalogByKey(s.key) != null)
            .where((s) => !_onlyOffers || s.offer != null)
            .toList();
        return Scaffold(
          appBar: AppBar(title: const Text('Paket & promo')),
          body: RefreshIndicator(
            color: AppColors.lime,
            onRefresh: promo.refresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
              children: [
                AppCard(
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Icon(Icons.info_outline_rounded, color: AppColors.muted, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${promo.note}${promo.updated.isNotEmpty ? '\nDiperbarui: ${promo.updated}' : ''}',
                        style: const TextStyle(color: AppColors.muted, fontSize: 13, height: 1.45),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 14),
                Wrap(spacing: 8, children: [
                  ChoiceChip(
                    label: const Text('Semua layanan'),
                    selected: !_onlyOffers,
                    showCheckmark: false,
                    onSelected: (_) => setState(() => _onlyOffers = false),
                  ),
                  ChoiceChip(
                    label: const Text('Ada promo'),
                    selected: _onlyOffers,
                    showCheckmark: false,
                    onSelected: (_) => setState(() => _onlyOffers = true),
                  ),
                ]),
                for (final s in list) ...[
                  const SizedBox(height: 14),
                  PromoCard(promo: s),
                ],
                if (list.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: Center(
                        child: Text('Belum ada data promo.',
                            style: TextStyle(color: AppColors.muted))),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Kartu paket satu layanan (dipakai juga di halaman detail).
class PromoCard extends StatelessWidget {
  final ServicePromo promo;
  /// Langganan pengguna untuk layanan ini (bila ada) → tampilkan perbandingan.
  final Subscription? mine;
  final bool compact;
  const PromoCard({super.key, required this.promo, this.mine, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final c = catalogByKey(promo.key)!;
    final my = mine ??
        Repo.instance.active.where((s) => s.catalogKey == promo.key).firstOrNull;
    final myMonthly = my?.monthlyCost;

    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (!compact)
          Row(children: [
            SubAvatar(logoKey: c.key, name: c.name, color: c.color, size: 42),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(c.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 2),
                Text(c.category, style: const TextStyle(color: AppColors.muted, fontSize: 12.5)),
              ]),
            ),
            if (my != null)
              const Pill('Langganan Anda', fg: AppColors.sky, bg: Color(0x265AC8FA)),
          ]),
        if (promo.offer != null) ...[
          if (!compact) const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.limeDeep,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.lime.withAlpha(60)),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.local_offer_rounded, color: AppColors.lime, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(promo.offer!,
                      style: const TextStyle(color: AppColors.lime, fontWeight: FontWeight.w700)),
                  if (promo.offerNote != null)
                    Text(promo.offerNote!,
                        style: TextStyle(color: AppColors.lime.withAlpha(190), fontSize: 12.5)),
                ]),
              ),
            ]),
          ),
        ],
        const SizedBox(height: 4),
        for (final p in promo.plans)
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => EditScreen(
                      existing: my,
                      fromCatalog: my == null ? c : null,
                      initialAmount: p.price,
                      initialCurrency: p.currency,
                      initialCycle: p.cycle,
                    ))),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    if (p.note != null)
                      Text(p.note!,
                          style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                    if (myMonthly != null && p.monthlyIdr < myMonthly - 500)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Pill('Hemat ${rupiah(myMonthly - p.monthlyIdr)}/bln',
                            fg: AppColors.lime, bg: AppColors.limeDeep,
                            icon: Icons.south_rounded),
                      ),
                  ]),
                ),
                const SizedBox(width: 10),
                Text(p.priceLabel,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontFeatures: kTabular)),
                const SizedBox(width: 6),
                const Icon(Icons.chevron_right_rounded, color: AppColors.faint, size: 20),
              ]),
            ),
          ),
        const Divider(),
        Row(children: [
          Expanded(
            child: Text('Sumber: ${promo.source}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.faint, fontSize: 11.5)),
          ),
          TextButton.icon(
            onPressed: () => openOfficial(context, promo.url),
            icon: const Icon(Icons.open_in_new_rounded, size: 16),
            label: const Text('Situs resmi'),
          ),
        ]),
      ]),
    );
  }
}
