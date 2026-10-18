import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/notification_service.dart';
import 'lock_screen.dart';
import '../services/repository.dart';
import '../utils/format.dart';
import '../widgets/common.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _pickHour(BuildContext context) async {
    final repo = Repo.instance;
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: repo.reminderHour, minute: 0),
      helpText: 'Jam pengingat',
    );
    if (t != null) await repo.setReminders(hour: t.hour);
  }

  void _toast(BuildContext context, String msg) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  /// Simpan cadangan sebagai file .json (pengguna memilih lokasi, mis. Download/Drive).
  Future<void> _exportFile(BuildContext context) async {
    final d = DateTime.now();
    final name = 'langgananku-cadangan-'
        '${d.year}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}.json';
    try {
      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'Simpan cadangan LanggananKu',
        fileName: name,
        type: FileType.custom,
        allowedExtensions: const ['json'],
        bytes: Uint8List.fromList(utf8.encode(Repo.instance.exportJson())),
      );
      if (path != null) _toast(context, 'Cadangan tersimpan: $name');
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: Repo.instance.exportJson()));
      _toast(context, 'Tidak bisa menyimpan file. Data cadangan disalin ke clipboard.');
    }
  }

  Future<void> _importFile(BuildContext context) async {
    try {
      final res = await FilePicker.platform.pickFiles(
        dialogTitle: 'Pilih file cadangan LanggananKu',
        type: FileType.any,
        withData: true,
      );
      final bytes = res?.files.single.bytes;
      if (bytes == null) return;
      if (!context.mounted) return;
      final ok = await _confirmReplace(context);
      if (ok != true) return;
      final n = await Repo.instance.importJson(utf8.decode(bytes));
      _toast(context, '$n langganan dipulihkan dari file.');
    } catch (_) {
      _toast(context, 'File bukan cadangan LanggananKu yang valid.');
    }
  }

  Future<bool?> _confirmReplace(BuildContext context) => showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Ganti data sekarang?'),
          content: const Text('Langganan di HP ini akan diganti dengan isi cadangan.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Pulihkan')),
          ],
        ),
      );

  Future<void> _toggleLock(BuildContext context, bool on) async {
    final repo = Repo.instance;
    if (on) {
      final pin = await Navigator.of(context)
          .push<String>(MaterialPageRoute(builder: (_) => const SetPinScreen()));
      if (pin != null) {
        await repo.setPin(pin);
        _toast(context, 'Kunci aplikasi aktif.');
      }
    } else {
      final ok = await Navigator.of(context).push<bool>(
          MaterialPageRoute(builder: (_) => const SetPinScreen(verifyOnly: true)));
      if (ok == true) {
        await repo.setPin(null);
        _toast(context, 'Kunci aplikasi dimatikan.');
      }
    }
  }

  Future<void> _editBudget(BuildContext context) async {
    final repo = Repo.instance;
    final ctrl = TextEditingController(
        text: repo.monthlyBudget > 0 ? repo.monthlyBudget.toStringAsFixed(0) : '');
    final v = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Batas anggaran per bulan'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: ctrl,
            autofocus: true,
            keyboardType: TextInputType.number,
            decoration: inputDeco('Maksimal per bulan', prefix: 'Rp '),
          ),
          const SizedBox(height: 10),
          Text('Total langganan Anda sekarang ${rupiah(repo.monthlyTotal)}/bln.',
              style: const TextStyle(fontSize: 13)),
        ]),
        actions: [
          if (repo.monthlyBudget > 0)
            TextButton(onPressed: () => Navigator.pop(ctx, 0.0), child: const Text('Matikan')),
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(
            onPressed: () => Navigator.pop(
                ctx, double.tryParse(ctrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    if (v != null) await repo.setBudget(v);
  }

  Future<void> _editRate(BuildContext context) async {
    final repo = Repo.instance;
    final ctrl = TextEditingController(text: repo.usdRate.toStringAsFixed(0));
    final v = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kurs dolar (USD)'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: ctrl,
            autofocus: true,
            keyboardType: TextInputType.number,
            decoration: inputDeco('1 US\$ =', prefix: 'Rp '),
          ),
          const SizedBox(height: 10),
          const Text(
            'Dipakai untuk menghitung langganan yang ditagih dalam dolar '
            '(mis. ChatGPT, Claude). Samakan dengan kurs di tagihan kartu Anda.',
            style: TextStyle(fontSize: 13),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(
            onPressed: () => Navigator.pop(
                ctx, double.tryParse(ctrl.text.replaceAll(RegExp(r'[^0-9]'), ''))),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    if (v != null && v > 0) await repo.setUsdRate(v);
  }

  Future<void> _import(BuildContext context) async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Impor data'),
        content: TextField(
          controller: ctrl,
          maxLines: 8,
          decoration: inputDeco('Data cadangan', hint: 'Tempel data cadangan (JSON)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Impor')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      final n = await Repo.instance.importJson(ctrl.text);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$n langganan diimpor.')));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Format data tidak valid.')));
      }
    }
  }

  Future<void> _clear(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus semua data?'),
        content: const Text('Semua langganan dan riwayat harga di HP ini akan dihapus.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Hapus')),
        ],
      ),
    );
    if (ok == true) await Repo.instance.clearAll();
  }

  @override
  Widget build(BuildContext context) {
    final repo = Repo.instance;
    return ListenableBuilder(
      listenable: repo,
      builder: (context, _) {
        final cs = Theme.of(context).colorScheme;
        return Scaffold(
          appBar: AppBar(title: const Text('Setelan')),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
            children: [
              const SectionTitle('Pengingat'),
              AppCard(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(children: [
                  SwitchListTile(
                    title: const Text('Pengingat jatuh tempo'),
                    subtitle: const Text('Atur H-7/H-3/H-1/Hari-H di tiap langganan'),
                    value: repo.remindersEnabled,
                    onChanged: (v) async {
                      if (v) await NotificationService.requestPermission();
                      await repo.setReminders(enabled: v);
                    },
                  ),
                  ListTile(
                    enabled: repo.remindersEnabled,
                    title: const Text('Jam pengingat'),
                    trailing: Text('${repo.reminderHour.toString().padLeft(2, '0')}.00'),
                    onTap: () => _pickHour(context),
                  ),
                  ListTile(
                    title: const Text('Kirim notifikasi uji'),
                    trailing: const Icon(Icons.notifications_outlined),
                    onTap: () async {
                      await NotificationService.requestPermission();
                      await NotificationService.showNow(
                          'LanggananKu', 'Notifikasi berfungsi. Pengingat akan muncul seperti ini.');
                    },
                  ),
                ]),
              ),
              const SectionTitle('Anggaran'),
              AppCard(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  leading: const Icon(Icons.account_balance_wallet_outlined),
                  title: const Text('Batas anggaran per bulan'),
                  subtitle: Text(repo.monthlyBudget > 0
                      ? 'Terpakai ${(repo.budgetUsed * 100).toStringAsFixed(0)}% · diberi tahu bila terlampaui'
                      : 'Belum diatur'),
                  trailing: Text(repo.monthlyBudget > 0 ? rupiah(repo.monthlyBudget) : 'Atur',
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  onTap: () => _editBudget(context),
                ),
              ),
              const SectionTitle('Keamanan'),
              AppCard(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(children: [
                  SwitchListTile(
                    secondary: const Icon(Icons.lock_outline_rounded),
                    title: const Text('Kunci aplikasi dengan PIN'),
                    subtitle: const Text('Diminta saat membuka LanggananKu'),
                    value: repo.lockEnabled,
                    onChanged: (v) => _toggleLock(context, v),
                  ),
                  if (repo.lockEnabled)
                    FutureBuilder<bool>(
                      future: Biometric.available(),
                      builder: (context, snap) => snap.data == true
                          ? SwitchListTile(
                              secondary: const Icon(Icons.fingerprint_rounded),
                              title: const Text('Buka dengan sidik jari / wajah'),
                              value: repo.bioEnabled,
                              onChanged: (v) async {
                                if (v && !await Biometric.authenticate()) return;
                                await repo.setBio(v);
                              },
                            )
                          : const SizedBox.shrink(),
                    ),
                ]),
              ),
              const SectionTitle('Mata uang'),
              AppCard(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  leading: const Icon(Icons.currency_exchange_rounded),
                  title: const Text('Kurs dolar (USD)'),
                  subtitle: const Text('Untuk langganan yang ditagih dalam dolar'),
                  trailing: Text(rupiah(repo.usdRate),
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  onTap: () => _editRate(context),
                ),
              ),
              const SectionTitle('Cadangan data'),
              AppCard(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(children: [
                  ListTile(
                    leading: const Icon(Icons.save_alt_rounded),
                    title: const Text('Simpan cadangan ke file'),
                    subtitle: const Text('File .json — simpan di Download atau Google Drive'),
                    onTap: () => _exportFile(context),
                  ),
                  ListTile(
                    leading: const Icon(Icons.restore_rounded),
                    title: const Text('Pulihkan dari file'),
                    subtitle: const Text('Pilih file cadangan LanggananKu'),
                    onTap: () => _importFile(context),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.copy_rounded),
                    title: const Text('Salin cadangan (teks)'),
                    subtitle: const Text('Alternatif: salin ke clipboard'),
                    onTap: () async {
                      await Clipboard.setData(ClipboardData(text: repo.exportJson()));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Data cadangan disalin.')));
                      }
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.download_outlined),
                    title: const Text('Tempel cadangan (teks)'),
                    onTap: () => _import(context),
                  ),
                  ListTile(
                    leading: Icon(Icons.delete_forever_outlined, color: cs.error),
                    title: Text('Hapus semua data', style: TextStyle(color: cs.error)),
                    onTap: () => _clear(context),
                  ),
                ]),
              ),
              const SectionTitle('Privasi'),
              const AppCard(
                child: Text(
                  'LanggananKu berjalan dalam mode tanpa akun: data langganan, SMS, dan '
                  'email yang dipindai diproses dan disimpan hanya di HP ini.',
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Text('LanggananKu v1.2.0',
                    style: TextStyle(color: cs.onSurfaceVariant)),
              ),
            ],
          ),
        );
      },
    );
  }
}
