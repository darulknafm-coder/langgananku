import 'package:flutter/material.dart';

import '../data/catalog.dart';
import '../models/subscription.dart';
import '../services/detector.dart';
import '../services/repository.dart';
import '../services/sms_scanner.dart';
import '../utils/format.dart';
import '../widgets/common.dart';

/// Deteksi otomatis: pindai SMS (Android) atau tempel teks email/nota (Android & iOS).
class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final _text = TextEditingController();
  bool _busy = false;
  int _scanned = 0;
  List<DetectedSubscription>? _results;

  static const _example = 'Pembayaran Rp65.000 ke NETFLIX.COM berhasil pada 05/10/2026 '
      'menggunakan Kartu Kredit BCA.\n\n'
      'Terima kasih! Langganan Spotify Premium Anda telah diperpanjang. '
      'Total IDR 54,990.00 - 12 Okt 2026\n\n'
      'Receipt from Anthropic: Claude Pro subscription, IDR 330.000, 1 Oct 2026';

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _scanSms() async {
    setState(() => _busy = true);
    try {
      final msgs = await SmsScanner.readInbox();
      _run(msgs);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _scanText() {
    FocusScope.of(context).unfocus();
    _run(Detector.splitPasted(_text.text));
  }

  void _run(List<RawMessage> msgs) {
    setState(() {
      _scanned = msgs.length;
      _results = Detector.detect(msgs, Repo.instance.subs);
    });
  }

  Future<void> _save() async {
    final repo = Repo.instance;
    var added = 0, updated = 0;
    for (final d in _results!.where((d) => d.selected)) {
      if (d.existing != null) {
        await repo.applyDetected(d.existing!, d.amount, d.nextDue);
        updated++;
      } else {
        final CatalogItem? c = d.item;
        await repo.add(Subscription(
          id: repo.newId(),
          name: d.name,
          category: c?.category ?? 'Lainnya',
          amount: d.amount,
          cycle: d.cycle,
          nextDue: d.nextDue,
          cancelUrl: c?.cancelUrl,
          color: c?.color ?? 0xFF64748B,
          catalogKey: c?.key,
          history: [PricePoint(d.lastCharge, d.amount)],
        ));
        added++;
      }
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('$added langganan ditambahkan, $updated diperbarui.')));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final results = _results;
    return Scaffold(
      appBar: AppBar(title: const Text('Deteksi otomatis')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
        children: [
          AppCard(
            color: cs.secondaryContainer,
            child: Row(children: [
              Icon(Icons.lock_outline, color: cs.onSecondaryContainer),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Semua pesan dianalisis di HP ini saja dan tidak dikirim ke mana pun.',
                  style: TextStyle(color: cs.onSecondaryContainer),
                ),
              ),
            ]),
          ),
          if (SmsScanner.supported) ...[
            const SectionTitle('1. Pindai SMS bank & e-wallet'),
            FilledButton.icon(
              onPressed: _busy ? null : _scanSms,
              icon: _busy
                  ? const SizedBox(
                      width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.sms_outlined),
              label: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('Pindai SMS 12 bulan terakhir'),
              ),
            ),
          ],
          SectionTitle(SmsScanner.supported
              ? '2. Atau tempel email / nota'
              : 'Tempel email nota / Apple receipt'),
          Text(
            'Salin isi email tagihan (mis. dari Gmail, Apple, Google Play) atau SMS, '
            'lalu tempel di bawah. Pisahkan beberapa pesan dengan baris kosong.',
            style: TextStyle(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _text,
            minLines: 5,
            maxLines: 12,
            decoration: inputDeco('Teks SMS / email', hint: 'Tempel teks di sini…'),
          ),
          const SizedBox(height: 8),
          Row(children: [
            TextButton(
              onPressed: () => setState(() => _text.text = _example),
              child: const Text('Isi contoh'),
            ),
            const Spacer(),
            FilledButton.tonal(onPressed: _scanText, child: const Text('Analisis teks')),
          ]),
          if (results != null) ...[
            SectionTitle('Hasil (${results.length} dari $_scanned pesan)'),
            if (results.isEmpty)
              const AppCard(
                child: Text(
                    'Tidak ditemukan tagihan langganan baru. Coba tempel teks lain, '
                    'atau tambah dari katalog.'),
              )
            else
              AppCard(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(children: [
                  for (final d in results)
                    CheckboxListTile(
                      value: d.selected,
                      onChanged: (v) => setState(() => d.selected = v ?? false),
                      secondary: SubAvatar(
                          name: d.name, color: d.item?.color ?? 0xFF64748B, size: 38),
                      title: Text(d.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(
                        d.priceChanged
                            ? 'Harga berubah: ${rupiah(d.existing!.amount)} → ${rupiah(d.amount)}'
                            : '${rupiah(d.amount)} · ${d.cycle.label} · '
                                'berikutnya ${tanggalPendek(d.nextDue)}'
                                '${d.occurrences > 1 ? ' · ${d.occurrences}x tertagih' : ''}',
                        style: TextStyle(color: d.priceChanged ? cs.error : null),
                      ),
                    ),
                ]),
              ),
          ],
        ],
      ),
      bottomNavigationBar: (results != null && results.any((d) => d.selected))
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton(
                  onPressed: _save,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Text('Simpan ${results.where((d) => d.selected).length} langganan'),
                  ),
                ),
              ),
            )
          : null,
    );
  }
}
