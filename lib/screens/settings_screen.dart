import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/notification_service.dart';
import '../services/repository.dart';
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

  Future<void> _import(BuildContext context) async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Impor data'),
        content: TextField(
          controller: ctrl,
          maxLines: 8,
          decoration: const InputDecoration(
              border: OutlineInputBorder(), hintText: 'Tempel data cadangan (JSON)'),
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
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
            children: [
              const SectionTitle('Pengingat'),
              AppCard(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(children: [
                  SwitchListTile(
                    title: const Text('Pengingat jatuh tempo'),
                    subtitle: const Text('Notifikasi H-3 dan H-1 sebelum ditagih'),
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
              const SectionTitle('Data'),
              AppCard(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(children: [
                  ListTile(
                    leading: const Icon(Icons.upload_outlined),
                    title: const Text('Ekspor (salin cadangan)'),
                    subtitle: const Text('Salin data ke clipboard untuk dipindah ke HP lain'),
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
                    title: const Text('Impor cadangan'),
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
                child: Text('LanggananKu v1.0.0',
                    style: TextStyle(color: cs.onSurfaceVariant)),
              ),
            ],
          ),
        );
      },
    );
  }
}
