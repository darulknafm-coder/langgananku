import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

const String kPrivacyUrl = 'https://darulknafm-coder.github.io/langgananku/privacy.html';

/// Layar masuk / daftar. Wajib sebelum memakai aplikasi.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _register = false;
  bool _busy = false;
  bool _showPass = false;
  bool _agree = false;
  String? _error;

  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _pass = TextEditingController();
  final _pass2 = TextEditingController();

  @override
  void dispose() {
    for (final c in [_name, _email, _phone, _pass, _pass2]) {
      c.dispose();
    }
    super.dispose();
  }

  void _switch(bool register) => setState(() {
        _register = register;
        _error = null;
      });

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_form.currentState!.validate()) return;
    if (_register && !_agree) {
      setState(() => _error = 'Centang persetujuan Kebijakan Privasi dulu.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (_register) {
        await AuthService.signUp(
          name: _name.text,
          email: _email.text,
          phone: _phone.text,
          password: _pass.text,
        );
      } else {
        await AuthService.signIn(_email.text, _pass.text);
      }
      // Berhasil → AppRoot otomatis pindah ke layar berikutnya.
    } on AuthFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Terjadi kesalahan. Periksa internet lalu coba lagi.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _forgot() async {
    final ctrl = TextEditingController(text: _email.text);
    final email = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Lupa password'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Kami kirim tautan untuk membuat password baru ke email Anda.'),
          const SizedBox(height: 14),
          TextField(
            controller: ctrl,
            keyboardType: TextInputType.emailAddress,
            decoration: inputDeco('Email'),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text.trim()), child: const Text('Kirim')),
        ],
      ),
    );
    if (email == null || email.isEmpty || !mounted) return;
    try {
      await AuthService.resetPassword(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Tautan dikirim ke $email. Cek juga folder Spam.')));
      }
    } on AuthFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  String? _req(String? v, String label) =>
      (v == null || v.trim().isEmpty) ? '$label wajib diisi' : null;

  String? _emailCheck(String? v) {
    final r = _req(v, 'Email');
    if (r != null) return r;
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v!.trim())
        ? null
        : 'Format email tidak valid';
  }

  String? _phoneCheck(String? v) {
    final r = _req(v, 'Nomor HP');
    if (r != null) return r;
    final n = AuthService.normalizePhone(v!);
    final digits = n.substring(3);
    if (!digits.startsWith('8') || digits.length < 9 || digits.length > 13) {
      return 'Contoh nomor yang benar: 0812 3456 7890';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(height: 14);
    return Scaffold(
      body: SafeArea(
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
            children: [
              // ---------- Merek ----------
              Row(children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                      color: AppColors.lime, borderRadius: BorderRadius.circular(16)),
                  child: Icon(Icons.autorenew_rounded, color: AppColors.onLime, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('LanggananKu',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                    Text('Semua tagihan langganan di satu tempat',
                        style: TextStyle(color: AppColors.muted, fontSize: 13.5)),
                  ]),
                ),
              ]),
              const SizedBox(height: 32),
              Text(_register ? 'Buat akun baru' : 'Masuk ke akun Anda',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(
                  _register
                      ? 'Data langganan Anda tersimpan aman di akun, jadi tidak hilang saat ganti HP.'
                      : 'Gunakan email dan password yang Anda daftarkan.',
                  style: TextStyle(color: AppColors.muted)),
              const SizedBox(height: 24),

              // ---------- Pilihan Masuk / Daftar ----------
              SegmentedButton<bool>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: false, label: Text('Masuk')),
                  ButtonSegment(value: true, label: Text('Daftar')),
                ],
                selected: {_register},
                onSelectionChanged: _busy ? null : (v) => _switch(v.first),
              ),
              const SizedBox(height: 22),

              if (_register) ...[
                TextFormField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.name],
                  decoration: inputDeco('Nama lengkap'),
                  validator: (v) => _req(v, 'Nama'),
                ),
                gap,
              ],
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                decoration: inputDeco('Email', hint: 'nama@gmail.com'),
                validator: _emailCheck,
              ),
              gap,
              if (_register) ...[
                TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.telephoneNumber],
                  decoration: inputDeco('Nomor HP', hint: '0812 3456 7890'),
                  validator: _phoneCheck,
                ),
                gap,
              ],
              TextFormField(
                controller: _pass,
                obscureText: !_showPass,
                textInputAction: _register ? TextInputAction.next : TextInputAction.done,
                autofillHints: [_register ? AutofillHints.newPassword : AutofillHints.password],
                onFieldSubmitted: (_) => _register ? null : _submit(),
                decoration: inputDeco('Password',
                        helper: _register ? 'Minimal 8 karakter' : null)
                    .copyWith(
                  suffixIcon: IconButton(
                    tooltip: _showPass ? 'Sembunyikan' : 'Tampilkan',
                    icon: Icon(_showPass ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                    onPressed: () => setState(() => _showPass = !_showPass),
                  ),
                ),
                validator: (v) {
                  final r = _req(v, 'Password');
                  if (r != null) return r;
                  if (_register && v!.length < 8) return 'Minimal 8 karakter';
                  return null;
                },
              ),
              if (_register) ...[
                gap,
                TextFormField(
                  controller: _pass2,
                  obscureText: !_showPass,
                  textInputAction: TextInputAction.done,
                  decoration: inputDeco('Ulangi password'),
                  validator: (v) => v != _pass.text ? 'Password tidak sama' : null,
                ),
                const SizedBox(height: 10),
                CheckboxListTile(
                  value: _agree,
                  onChanged: (v) => setState(() => _agree = v ?? false),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text.rich(TextSpan(children: [
                    const TextSpan(text: 'Saya setuju dengan '),
                    WidgetSpan(
                      alignment: PlaceholderAlignment.baseline,
                      baseline: TextBaseline.alphabetic,
                      child: GestureDetector(
                        onTap: () => launchUrl(Uri.parse(kPrivacyUrl),
                            mode: LaunchMode.externalApplication),
                        child: Text('Kebijakan Privasi',
                            style: TextStyle(
                                color: AppColors.accentText,
                                fontWeight: FontWeight.w700,
                                decoration: TextDecoration.underline)),
                      ),
                    ),
                  ])),
                ),
              ] else
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(onPressed: _busy ? null : _forgot, child: const Text('Lupa password?')),
                ),

              if (_error != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: AppColors.coralDeep, borderRadius: BorderRadius.circular(12)),
                  child: Row(children: [
                    Icon(Icons.error_outline_rounded, color: AppColors.coral, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                        child: Text(_error!,
                            style: TextStyle(color: AppColors.coral, fontWeight: FontWeight.w600))),
                  ]),
                ),
              ],
              const SizedBox(height: 18),
              FilledButton(
                onPressed: _busy ? null : _submit,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: _busy
                      ? SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.muted))
                      : Text(_register ? 'Daftar' : 'Masuk'),
                ),
              ),
              const SizedBox(height: 14),
              Center(
                child: TextButton(
                  onPressed: _busy ? null : () => _switch(!_register),
                  child: Text(_register
                      ? 'Sudah punya akun? Masuk'
                      : 'Belum punya akun? Daftar sekarang'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
