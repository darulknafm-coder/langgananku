import 'package:flutter/material.dart';

import '../data/catalog.dart';
import '../models/subscription.dart';
import '../services/detector.dart';
import '../services/repository.dart';
import '../utils/format.dart';
import '../widgets/common.dart';

/// Tambah baru (opsional dari item katalog) atau edit langganan yang ada.
class EditScreen extends StatefulWidget {
  final Subscription? existing;
  final CatalogItem? fromCatalog;
  const EditScreen({super.key, this.existing, this.fromCatalog});

  @override
  State<EditScreen> createState() => _EditScreenState();
}

class _EditScreenState extends State<EditScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _amount;
  late final TextEditingController _url;
  late final TextEditingController _note;
  late String _category;
  late BillingCycle _cycle;
  late DateTime _due;
  late String _payment;
  late Usage _usage;
  late int _shared;
  late bool _active;
  late int _color;
  String? _catalogKey;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    final c = widget.fromCatalog;
    _name = TextEditingController(text: e?.name ?? c?.name ?? '');
    _amount = TextEditingController(
        text: (e?.amount ?? c?.monthly)?.toStringAsFixed(0) ?? '');
    _url = TextEditingController(text: e?.cancelUrl ?? c?.cancelUrl ?? '');
    _note = TextEditingController(text: e?.note ?? '');
    _category = e?.category ?? c?.category ?? 'Lainnya';
    if (!kCategories.contains(_category)) _category = 'Lainnya';
    _cycle = e?.cycle ?? BillingCycle.monthly;
    _due = e?.nextDue ?? addMonths(dateOnly(DateTime.now()), 1);
    _payment = e?.paymentMethod ?? 'Kartu Kredit';
    if (!kPaymentMethods.contains(_payment)) _payment = 'Lainnya';
    _usage = e?.usage ?? Usage.often;
    _shared = e?.sharedWith ?? 1;
    _active = e?.active ?? true;
    _color = e?.color ?? c?.color ?? 0xFF0F766E;
    _catalogKey = e?.catalogKey ?? c?.key;
  }

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    _url.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _due,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
      helpText: 'Tanggal tagihan berikutnya',
    );
    if (d != null) setState(() => _due = d);
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final amount = Detector.parseRupiah(_amount.text) ?? 0;
    final repo = Repo.instance;
    final e = widget.existing;
    if (e == null) {
      await repo.add(Subscription(
        id: repo.newId(),
        name: _name.text.trim(),
        category: _category,
        amount: amount,
        cycle: _cycle,
        nextDue: _due,
        paymentMethod: _payment,
        cancelUrl: _url.text.trim().isEmpty ? null : _url.text.trim(),
        note: _note.text.trim(),
        active: _active,
        color: _color,
        usage: _usage,
        sharedWith: _shared,
        catalogKey: _catalogKey,
      ));
    } else {
      e
        ..name = _name.text.trim()
        ..category = _category
        ..cycle = _cycle
        ..paymentMethod = _payment
        ..cancelUrl = _url.text.trim().isEmpty ? null : _url.text.trim()
        ..note = _note.text.trim()
        ..active = _active
        ..usage = _usage
        ..sharedWith = _shared;
      if (dateOnly(e.nextDue) != dateOnly(_due)) {
        e.nextDue = _due;
        e.anchorDay = _due.day;
      }
      await repo.update(e, newAmount: amount);
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    const gap = SizedBox(height: 14);
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit langganan' : 'Tambah langganan')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (widget.fromCatalog != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Text(
                  'Harga dari katalog adalah perkiraan. Sesuaikan dengan tagihan Anda.',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ),
            TextFormField(
              controller: _name,
              decoration: inputDeco('Nama layanan', hint: 'mis. Netflix'),
              textCapitalization: TextCapitalization.words,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
            ),
            gap,
            TextFormField(
              controller: _amount,
              decoration: inputDeco('Nominal per tagihan', prefix: 'Rp '),
              keyboardType: TextInputType.number,
              validator: (v) {
                final n = Detector.parseRupiah(v ?? '');
                return (n == null || n <= 0) ? 'Isi nominal yang valid' : null;
              },
            ),
            gap,
            const Text('Siklus tagihan'),
            const SizedBox(height: 6),
            SegmentedButton<BillingCycle>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: BillingCycle.weekly, label: Text('Mgg')),
                ButtonSegment(value: BillingCycle.monthly, label: Text('Bln')),
                ButtonSegment(value: BillingCycle.quarterly, label: Text('3 Bln')),
                ButtonSegment(value: BillingCycle.yearly, label: Text('Thn')),
              ],
              selected: {_cycle},
              onSelectionChanged: (v) => setState(() => _cycle = v.first),
            ),
            gap,
            InkWell(
              onTap: _pickDate,
              child: InputDecorator(
                decoration: inputDeco('Tagihan berikutnya'),
                child: Row(children: [
                  Expanded(child: Text(tanggal(_due))),
                  const Icon(Icons.calendar_today_outlined, size: 18),
                ]),
              ),
            ),
            gap,
            DropdownButtonFormField<String>(
              value: _category,
              decoration: inputDeco('Kategori'),
              items: [for (final c in kCategories) DropdownMenuItem(value: c, child: Text(c))],
              onChanged: (v) => setState(() => _category = v ?? _category),
            ),
            gap,
            DropdownButtonFormField<String>(
              value: _payment,
              decoration: inputDeco('Metode pembayaran'),
              items: [for (final p in kPaymentMethods) DropdownMenuItem(value: p, child: Text(p))],
              onChanged: (v) => setState(() => _payment = v ?? _payment),
            ),
            gap,
            const Text('Seberapa sering dipakai?'),
            const SizedBox(height: 6),
            SegmentedButton<Usage>(
              showSelectedIcon: false,
              segments: [
                for (final u in Usage.values) ButtonSegment(value: u, label: Text(u.label)),
              ],
              selected: {_usage},
              onSelectionChanged: (v) => setState(() => _usage = v.first),
            ),
            gap,
            Row(children: [
              const Expanded(
                child: Text('Dibagi dengan (mode keluarga/patungan)'),
              ),
              IconButton(
                onPressed: _shared > 1 ? () => setState(() => _shared--) : null,
                icon: const Icon(Icons.remove_circle_outline),
              ),
              Text('$_shared orang', style: const TextStyle(fontWeight: FontWeight.w700)),
              IconButton(
                onPressed: _shared < 12 ? () => setState(() => _shared++) : null,
                icon: const Icon(Icons.add_circle_outline),
              ),
            ]),
            gap,
            TextFormField(
              controller: _url,
              decoration: inputDeco('Link pembatalan (opsional)',
                  helper: 'Dipakai tombol "Batalkan langganan"'),
              keyboardType: TextInputType.url,
            ),
            gap,
            TextFormField(
              controller: _note,
              decoration: inputDeco('Catatan (opsional)'),
              maxLines: 2,
            ),
            if (isEdit)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Langganan aktif'),
                value: _active,
                onChanged: (v) => setState(() => _active = v),
              ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _save,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Text('Simpan'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
