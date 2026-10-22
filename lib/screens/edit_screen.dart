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
  /// Isi awal dari halaman Paket & Promo (paket yang dipilih).
  final double? initialAmount;
  final String? initialCurrency;
  final BillingCycle? initialCycle;
  final String? initialName;
  const EditScreen(
      {super.key,
      this.existing,
      this.fromCatalog,
      this.initialAmount,
      this.initialCurrency,
      this.initialCycle,
      this.initialName});

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
    _name = TextEditingController(text: e?.name ?? c?.name ?? widget.initialName ?? '');
    _currency = widget.initialCurrency ?? e?.currency ?? c?.currency ?? 'IDR';
    _trial = e?.onTrial ?? false;
    _reminders = {...(e?.reminderDays ?? const [3, 1])};
    final a = widget.initialAmount ?? e?.amount ?? c?.monthly;
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
    _cycle = widget.initialCycle ?? e?.cycle ?? BillingCycle.monthly;
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
    if (!mounted) return;
    if (widget.existing == null) {
      // Langganan baru: kembali ke layar utama dan beri konfirmasi.
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).popUntil((r) => r.isFirst);
      messenger.showSnackBar(SnackBar(content: Text('${_name.text.trim()} ditambahkan.')));
    } else {
      Navigator.of(context).pop();
    }
  }

  String _usdHelper() {
    final n = parseUsd(_amount.text);
    final rate = Repo.instance.usdRate;
    if (n == null || n <= 0) return 'Kurs ${rupiah(rate)}/US\$ (ubah di Setelan)';
    return '≈ ${rupiah(n * rate)} · kurs ${rupiah(rate)}/US\$';
  }

  Widget _label(String text, {String? help}) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(text, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          if (help != null) ...[
            const SizedBox(height: 2),
            Text(help, style: TextStyle(color: AppColors.muted, fontSize: 12.5)),
          ],
        ]),
      );

  Widget _choice<T>(List<(T, String)> items, T value, ValueChanged<T> onPick) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final (v, l) in items)
            ChoiceChip(
              label: Text(l),
              selected: v == value,
              showCheckmark: false,
              onSelected: (_) => setState(() => onPick(v)),
            ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    final c = widget.fromCatalog;
    final showNameField = c == null || isEdit;
    const gap = SizedBox(height: 22);

    final essentials = <Widget>[
      // ---------- Layanan ----------
      if (c != null && !isEdit)
        AppCard(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            SubAvatar(logoKey: c.key, name: c.name, color: c.color, size: 44),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(c.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                Text(c.category, style: TextStyle(color: AppColors.muted, fontSize: 13)),
              ]),
            ),
            TextButton(
                onPressed: () => Navigator.of(context).pop(), child: const Text('Ganti')),
          ]),
        ),
      if (showNameField) ...[
        _label('Nama layanan'),
        TextFormField(
          controller: _name,
          decoration: inputDeco('Contoh: Netflix, Wifi rumah, Gym'),
          textCapitalization: TextCapitalization.words,
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null,
        ),
      ],
      gap,

      // ---------- Harga ----------
      _label('Harga',
          help: c != null && !isEdit
              ? 'Sudah diisi harga umum. Sesuaikan dengan tagihan Anda.'
              : 'Jumlah yang ditagih setiap kali bayar.'),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          child: TextFormField(
            controller: _amount,
            decoration: inputDeco('Harga',
                prefix: _currency == 'USD' ? 'US\$ ' : 'Rp ',
                helper: _currency == 'USD' ? _usdHelper() : null),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            onChanged: (_) {
              if (_currency == 'USD') setState(() {});
            },
            validator: (v) {
              final n = _parseAmount(v ?? '');
              return (n == null || n <= 0) ? 'Isi harga, contoh 65000' : null;
            },
          ),
        ),
        const SizedBox(width: 10),
        Padding(
          padding: const EdgeInsets.only(top: 6),
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

      // ---------- Bayar setiap ----------
      _label('Bayar setiap'),
      _choice<BillingCycle>([
        (BillingCycle.monthly, 'Bulan'),
        (BillingCycle.yearly, 'Tahun'),
        (BillingCycle.quarterly, '3 bulan'),
        (BillingCycle.weekly, 'Minggu'),
      ], _cycle, (v) => _cycle = v),
      gap,

      // ---------- Tanggal ----------
      _label(_trial ? 'Masa gratis berakhir' : 'Tanggal bayar berikutnya',
          help: _trial
              ? 'Hari pertama Anda akan ditagih. Kami ingatkan sebelum tanggal ini.'
              : 'Lihat di email atau struk terakhir. Bisa diubah kapan saja.'),
      InkWell(
        onTap: _pickDate,
        borderRadius: BorderRadius.circular(14),
        child: InputDecorator(
          decoration: inputDeco(''),
          child: Row(children: [
            Icon(Icons.event_rounded, color: AppColors.accentText, size: 20),
            const SizedBox(width: 10),
            Expanded(
                child: Text(tanggal(_due),
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15.5))),
            Text(sisaHari(_due), style: TextStyle(color: AppColors.muted, fontSize: 13)),
          ]),
        ),
      ),
      const SizedBox(height: 10),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('Masih gratis (masa percobaan)'),
        subtitle: const Text('Aktifkan bila belum pernah bayar'),
        value: _trial,
        onChanged: (v) => setState(() => _trial = v),
      ),
    ];

    final extras = <Widget>[
      _label('Ingatkan saya', help: 'Notifikasi sebelum tanggal bayar.'),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final d in kReminderChoices)
          FilterChip(
            label: Text(d == 0 ? 'Di hari bayar' : '$d hari sebelum'),
            selected: _reminders.contains(d),
            showCheckmark: false,
            onSelected: (v) => setState(() => v ? _reminders.add(d) : _reminders.remove(d)),
          ),
      ]),
      gap,
      _label('Bayar pakai'),
      DropdownButtonFormField<String>(
        value: _payment,
        decoration: inputDeco(''),
        items: [for (final p in kPaymentMethods) DropdownMenuItem(value: p, child: Text(p))],
        onChanged: (v) => setState(() => _payment = v ?? _payment),
      ),
      gap,
      _label('Jenis layanan'),
      DropdownButtonFormField<String>(
        value: _category,
        decoration: inputDeco(''),
        items: [for (final k in kCategories) DropdownMenuItem(value: k, child: Text(k))],
        onChanged: (v) => setState(() => _category = v ?? _category),
      ),
      gap,
      _label('Seberapa sering Anda pakai?',
          help: 'Dipakai untuk saran hemat. Yang jarang dipakai akan kami tandai.'),
      _choice<Usage>([
        (Usage.often, 'Sering'),
        (Usage.sometimes, 'Kadang-kadang'),
        (Usage.rarely, 'Jarang'),
      ], _usage, (v) => _usage = v),
      gap,
      _label('Dipakai bareng berapa orang?',
          help: 'Misalnya Netflix patungan bertiga. Biaya Anda dihitung per orang.'),
      Row(children: [
        IconButton.outlined(
          onPressed: _shared > 1 ? () => setState(() => _shared--) : null,
          icon: const Icon(Icons.remove_rounded),
        ),
        Expanded(
          child: Text(_shared == 1 ? 'Sendiri' : '$_shared orang',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        ),
        IconButton.outlined(
          onPressed: _shared < 12 ? () => setState(() => _shared++) : null,
          icon: const Icon(Icons.add_rounded),
        ),
      ]),
      gap,
      if (!showNameField) ...[
        _label('Nama layanan'),
        TextFormField(
          controller: _name,
          decoration: inputDeco(''),
          textCapitalization: TextCapitalization.words,
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null,
        ),
        gap,
      ],
      _label('Catatan'),
      TextFormField(
        controller: _note,
        decoration: inputDeco('', hint: 'Contoh: akun bersama keluarga'),
        maxLines: 2,
      ),
      gap,
      _label('Link untuk berhenti langganan',
          help: 'Dipakai tombol "Batalkan langganan". Boleh dikosongkan.'),
      TextFormField(
        controller: _url,
        decoration: inputDeco('', hint: 'https://…'),
        keyboardType: TextInputType.url,
      ),
      if (isEdit)
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Masih berlangganan'),
          subtitle: const Text('Matikan bila sudah berhenti; tidak dihitung lagi'),
          value: _active,
          onChanged: (v) => setState(() => _active = v),
        ),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Ubah langganan' : 'Tambah langganan')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          children: [
            ...essentials,
            const SizedBox(height: 8),
            AppCard(
              padding: EdgeInsets.zero,
              child: ExpansionTile(
                initiallyExpanded: isEdit,
                tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                childrenPadding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                expandedCrossAxisAlignment: CrossAxisAlignment.start,
                leading: const Icon(Icons.tune_rounded),
                title: const Text('Pengaturan tambahan',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text('Opsional: pengingat, cara bayar, patungan, catatan',
                    style: TextStyle(color: AppColors.muted, fontSize: 12.5)),
                children: extras,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: FilledButton(
            onPressed: _save,
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Text('Simpan'),
            ),
          ),
        ),
      ),
    );
  }
}
