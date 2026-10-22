import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/sync_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

/// Kartu akun di Setelan: profil, status email, ubah profil, keluar, hapus akun.
class AccountSection extends StatefulWidget {
  const AccountSection({super.key});

  @override
  State<AccountSection> createState() => _AccountSectionState();
}

class _AccountSectionState extends State<AccountSection> {
  UserProfile? _p;
  bool _verified = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await AuthService.profile();
    final v = await AuthService.refreshVerified();
    if (mounted) {
      setState(() {
        _p = p;
        _verified = v;
      });
    }
  }

  void _toast(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(m)));
  }

  Future<void> _edit() async {
    final name = TextEditingController(text: _p?.name ?? '');
    final phone = TextEditingController(text: _p?.phone ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ubah profil'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
              controller: name,
              textCapitalization: TextCapitalization.words,
              decoration: inputDeco('Nama lengkap')),
          const SizedBox(height: 12),
          TextField(
              controller: phone,
              keyboardType: TextInputType.phone,
              decoration: inputDeco('Nomor HP', hint: '0812 3456 7890')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Simpan')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await AuthService.updateProfile(name: name.text, phone: phone.text);
      await _load();
      _toast('Profil diperbarui.');
    } catch (_) {
      _toast('Gagal menyimpan. Periksa internet lalu coba lagi.');
    }
  }

  Future<void> _signOut() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar dari akun?'),
        content: const Text(
            'Data Anda tetap tersimpan di akun. Saat masuk lagi, semua langganan akan kembali.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Keluar')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final nav = Navigator.of(context);
    await SyncService.stop();
    await AuthService.signOut();
    nav.popUntil((r) => r.isFirst);
  }

  Future<void> _delete() async {
    final pass = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus akun permanen?'),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text(
              'Akun, profil, dan semua data langganan Anda akan dihapus dari server dan dari HP ini. '
              'Tindakan ini tidak bisa dibatalkan.'),
          const SizedBox(height: 14),
          TextField(
            controller: pass,
            obscureText: true,
            decoration: inputDeco('Masukkan password untuk konfirmasi'),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.coral, foregroundColor: AppColors.onCoral),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus akun'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final nav = Navigator.of(context);
    try {
      await AuthService.deleteAccount(pass.text);
      await SyncService.stop(uploadFirst: false);
      nav.popUntil((r) => r.isFirst);
    } on AuthFailure catch (e) {
      _toast(e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _p;
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(children: [
        ListTile(
          leading: SubAvatar(
              logo: false,
              name: (p?.name.isNotEmpty ?? false) ? p!.name : '?',
              color: AppColors.lime.toARGB32(),
              size: 42),
          title: Text(p == null ? 'Memuat…' : (p.name.isEmpty ? 'Tanpa nama' : p.name),
              style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text([if (p != null) p.email, if (p != null && p.phone.isNotEmpty) p.phone]
              .join('\n')),
          isThreeLine: p != null && p.phone.isNotEmpty,
          trailing: IconButton(
            tooltip: 'Ubah profil',
            icon: const Icon(Icons.edit_outlined),
            onPressed: p == null ? null : _edit,
          ),
        ),
        if (!_verified)
          ListTile(
            leading: Icon(Icons.mark_email_unread_outlined, color: AppColors.amber),
            title: const Text('Email belum diverifikasi'),
            subtitle: const Text('Ketuk untuk kirim ulang tautan verifikasi'),
            onTap: () async {
              try {
                await AuthService.resendVerification();
                _toast('Tautan verifikasi dikirim. Cek juga folder Spam.');
              } on AuthFailure catch (e) {
                _toast(e.message);
              }
            },
          ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.cloud_done_outlined),
          title: const Text('Data tersimpan otomatis di akun'),
          subtitle: const Text('Aman saat ganti HP — cukup masuk dengan akun yang sama'),
          onTap: () async {
            await SyncService.upload();
            _toast('Data sudah tersimpan di akun.');
          },
        ),
        ListTile(
          leading: const Icon(Icons.logout_rounded),
          title: const Text('Keluar'),
          onTap: _signOut,
        ),
        ListTile(
          leading: Icon(Icons.person_remove_outlined, color: AppColors.coral),
          title: Text('Hapus akun', style: TextStyle(color: AppColors.coral)),
          onTap: _delete,
        ),
      ]),
    );
  }
}
