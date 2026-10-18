import 'package:flutter/material.dart';

import '../data/catalog.dart';
import '../models/subscription.dart';
import '../services/detector.dart';
import '../services/repository.dart';
import '../theme/app_theme.dart';
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
  late String _currency;
  late bool _trial;
  late Set<int> _reminders;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    final c = widget.fromCatalog;
    _name = TextEditingController(text: e?.name ?? c?.name ?? '');
    _currency = e?.currency ?? 'IDR';
    _trial = e?.onTrial ?? false;
    _reminders = {...(e?.reminderDays ?? const [3, 1])};
    final a = e?.amount ?? c?.monthly;
    _amount = TextEditingController(
        text: a == null
            ? ''
            : (_currency == 'USD' && a != a.roundToDouble())
                ? a.toStringAsFixed(2)
                : a.toStringAsFixed(0));
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
      helpText: _trial ? 'Trial gratis berakhir' : 'Tanggal tagihan berikutnya',
    );
    if (d != null) setState(() => _due = d);
  }

  List<int> _sortedReminders() => _reminders.toList()..sort((a, b) => b.compareTo(a));

  double? _parseAmount(String v) =>
      _currency == 'USD' ? parseUsd(v) : Detector.parseRupiah(v);

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final amount = _parseAmount(_amount.text) ?? 0;
    final trialEnd = _trial ? dateOnly(_due) : null;
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
        currency: _currency,
        trialEnd: trialEnd,
        reminderDays: _sortedReminders(),
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
        ..sharedWith = _shared
        ..trialEnd = trialEnd
        ..reminderDays = _sortedReminders();
      if (e.members.length > _shared - 1) {
        e.members = e.members.take(_shared - 1 < 0 ? 0 : _shared - 1).toList();
      }
      if (e.currency != _currency) {
        // Ganti mata uang: riwayat harga lama tidak sebanding, mulai ulang.
        e
          ..currency = _currency
          ..amount = amount
          ..history = [PricePoint(DateTime.now(), amount)];
      }
      if (dateOnly(e.nextDue) != dateOnly(_due)) {
        e.nextDue = _due;
        e.anchorDay = _due.day;
      }
      await repo.update(e, newAmount: amount);
    }
    if (mounted) Navigator.of(context).pop();
  }

  String _usdHelper() {
    final n = parseUsd(_amount.text);
    final rate = Repo.instance.usdRate;
    if (n == null || n <= 0) return 'Kurs ${rupiah(rate)}/US\$ (ubah di Setelan)';
    return '≈ ${rupiah(n * rate)} · kurs ${rupiah(rate)}/US\$';
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
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                child: TextFormField(
                  controller: _amount,
                  decoration: inputDeco('Nominal per tagihan',
                      prefix: _currency == 'USD' ? 'US\$ ' : 'Rp ',
                      helper: _currency == 'USD' ? _usdHelper() : null),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) {
                    if (_currency == 'USD') setState(() {});
                  },
                  validator: (v) {
                    final n = _parseAmount(v ?? '');
                    return (n == null || n <= 0) ? 'Isi nominal yang valid' : null;
                  },
                ),
              ),
              const SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: SegmentedButton<String>(
                  showSelectedIcon: false,
                  style: const ButtonStyle(visualDensity: VisualDensity.compact),
                  segments: const [
                    ButtonSegment(value: 'IDR', label: Text('Rp')),
                    ButtonSegment(value: 'USD', label: Text('US\$')),
                  ],
                  selected: {_currency},
                  onSelectionChanged: (v) => setState(() => _currency = v.first),
                ),
              ),
            ]),
            gap,
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                secondary: const Icon(Icons.hourglass_top_rounded),
                title: const Text('Sedang masa trial gratis'),
                subtitle: const Text('Diingatkan H-3, H-1, dan di hari terakhir trial'),
                value: _trial,
                onChanged: (v) => setState(() => _trial = v),
              ),
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
                decoration: inputDeco(_trial
                    ? 'Trial gratis berakhir (tagihan pertama)'
                    : 'Tagihan berikutnya'),
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
            const Text('Ingatkan saya'),
            const SizedBox(height: 6),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final d in kReminderChoices)
                FilterChip(
                  label: Text(reminderLabel(d)),
                  selected: _reminders.contains(d),
                  showCheckmark: false,
                  onSelected: (v) => setState(() => v ? _reminders.add(d) : _reminders.remove(d)),
                ),
            ]),
            if (_reminders.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text('Tanpa pengingat untuk langganan ini.',
                    style: TextStyle(fontSize: 12.5, color: AppColors.muted)),
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
