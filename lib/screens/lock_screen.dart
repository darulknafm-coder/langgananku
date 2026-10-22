import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

import '../services/repository.dart';
import '../theme/app_theme.dart';

const int kPinLength = 4;

/// Sidik jari / Face ID (bila perangkat mendukung).
class Biometric {
  static final _auth = LocalAuthentication();

  static Future<bool> available() async {
    if (kIsWeb) return false;
    try {
      return await _auth.isDeviceSupported() && await _auth.canCheckBiometrics;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> authenticate() async {
    if (kIsWeb) return false;
    try {
      return await _auth.authenticate(
        localizedReason: 'Buka LanggananKu',
        options: const AuthenticationOptions(biometricOnly: true, stickyAuth: true),
      );
    } catch (_) {
      return false;
    }
  }
}

/// Membungkus seluruh aplikasi: tampilkan layar kunci saat dibuka dan
/// saat kembali dari latar belakang lebih dari 30 detik.
class LockGate extends StatefulWidget {
  final Widget child;
  const LockGate({super.key, required this.child});

  @override
  State<LockGate> createState() => _LockGateState();
}

class _LockGateState extends State<LockGate> with WidgetsBindingObserver {
  late bool _locked;
  DateTime? _pausedAt;
  static bool authBusy = false;

  @override
  void initState() {
    super.initState();
    _locked = Repo.instance.lockEnabled;
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (authBusy) return;
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      _pausedAt ??= DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      final away = _pausedAt == null ? Duration.zero : DateTime.now().difference(_pausedAt!);
      _pausedAt = null;
      if (Repo.instance.lockEnabled && away > const Duration(seconds: 30)) {
        setState(() => _locked = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      widget.child,
      if (_locked)
        Positioned.fill(
          child: _LockScreen(onUnlocked: () => setState(() => _locked = false)),
        ),
    ]);
  }
}

class _LockScreen extends StatefulWidget {
  final VoidCallback onUnlocked;
  const _LockScreen({required this.onUnlocked});

  @override
  State<_LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<_LockScreen> {
  String _pin = '';
  String? _error;
  bool _forgot = false;
  bool _bio = false;

  @override
  void initState() {
    super.initState();
    if (Repo.instance.bioEnabled) {
      Biometric.available().then((v) {
        if (!mounted) return;
        setState(() => _bio = v);
        if (v) _tryBio();
      });
    }
  }

  Future<void> _tryBio() async {
    _LockGateState.authBusy = true;
    final ok = await Biometric.authenticate();
    // beri jeda agar event lifecycle dari dialog sistem tidak mengunci ulang
    await Future<void>.delayed(const Duration(milliseconds: 400));
    _LockGateState.authBusy = false;
    if (ok && mounted) widget.onUnlocked();
  }

  void _press(String d) {
    if (_pin.length >= kPinLength) return;
    HapticFeedback.selectionClick();
    setState(() {
      _pin += d;
      _error = null;
    });
    if (_pin.length == kPinLength) {
      if (Repo.instance.checkPin(_pin)) {
        widget.onUnlocked();
      } else {
        HapticFeedback.heavyImpact();
        setState(() {
          _pin = '';
          _error = 'PIN salah, coba lagi';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.bg,
      child: SafeArea(
        child: _forgot ? _forgotView() : PinPad(
          title: 'Masukkan PIN',
          subtitle: _error ?? 'LanggananKu terkunci',
          error: _error != null,
          length: _pin.length,
          onDigit: _press,
          onDelete: () => setState(() => _pin = _pin.isEmpty ? '' : _pin.substring(0, _pin.length - 1)),
          extra: _bio
              ? IconButton(
                  onPressed: _tryBio,
                  icon: Icon(Icons.fingerprint_rounded, size: 34, color: AppColors.lime),
                )
              : null,
          footer: TextButton(
            onPressed: () => setState(() => _forgot = true),
            child: const Text('Lupa PIN?'),
          ),
        ),
      ),
    );
  }

  Widget _forgotView() {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.lock_reset_rounded, size: 48, color: AppColors.coral),
        const SizedBox(height: 16),
        const Text('Lupa PIN?',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        Text(
          'Demi keamanan, PIN tidak bisa dipulihkan. Anda bisa menghapus semua data '
          'di HP ini untuk membuka aplikasi. Bila punya file cadangan, data bisa dipulihkan lagi.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.muted),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.coral),
            onPressed: () async {
              await Repo.instance.clearAll();
              await Repo.instance.setPin(null);
              widget.onUnlocked();
            },
            child: const Text('Hapus semua data & buka'),
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => setState(() => _forgot = false),
          child: const Text('Kembali'),
        ),
      ]),
    );
  }
}

/// Papan angka PIN (dipakai layar kunci dan layar atur PIN).
/// Sengaja tanpa Tooltip, karena layar kunci tampil di atas Navigator.
class PinPad extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool error;
  final int length;
  final ValueChanged<String> onDigit;
  final VoidCallback onDelete;
  final Widget? extra;
  final Widget? footer;
  const PinPad({
    super.key,
    required this.title,
    required this.subtitle,
    required this.length,
    required this.onDigit,
    required this.onDelete,
    this.error = false,
    this.extra,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    Widget key(Widget child, VoidCallback? onTap) => Expanded(
          child: AspectRatio(
            aspectRatio: 1.35,
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Material(
                color: onTap == null ? Colors.transparent : AppColors.surface,
                shape: const StadiumBorder(),
                child: InkWell(
                  customBorder: const StadiumBorder(),
                  onTap: onTap,
                  child: Center(child: child),
                ),
              ),
            ),
          ),
        );
    Widget digit(String d) => key(
        Text(d, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
        () => onDigit(d));

    return LayoutBuilder(builder: (context, c) {
      return SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: c.maxHeight),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                    color: AppColors.limeDeep, borderRadius: BorderRadius.circular(20)),
                child: Icon(Icons.lock_rounded, color: AppColors.lime, size: 28),
              ),
              const SizedBox(height: 18),
              Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: error ? AppColors.coral : AppColors.muted)),
              const SizedBox(height: 24),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                for (var i = 0; i < kPinLength; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    width: 16,
                    height: 16,
                    margin: const EdgeInsets.symmetric(horizontal: 9),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i < length ? (error ? AppColors.coral : AppColors.lime) : null,
                      border: Border.all(
                          color: i < length ? Colors.transparent : AppColors.muted, width: 1.6),
                    ),
                  ),
              ]),
              const SizedBox(height: 28),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 340),
                child: Column(children: [
                  Row(children: [digit('1'), digit('2'), digit('3')]),
                  Row(children: [digit('4'), digit('5'), digit('6')]),
                  Row(children: [digit('7'), digit('8'), digit('9')]),
                  Row(children: [
                    key(extra ?? const SizedBox.shrink(), null),
                    digit('0'),
                    key(Icon(Icons.backspace_outlined, color: AppColors.muted), onDelete),
                  ]),
                ]),
              ),
              if (footer != null) ...[const SizedBox(height: 8), footer!],
            ]),
          ),
        ),
      );
    });
  }
}

/// Layar atur PIN baru (2 langkah) atau verifikasi PIN lama.
/// Mengembalikan PIN baru, atau `true` bila verifikasi berhasil.
class SetPinScreen extends StatefulWidget {
  final bool verifyOnly;
  const SetPinScreen({super.key, this.verifyOnly = false});

  @override
  State<SetPinScreen> createState() => _SetPinScreenState();
}

class _SetPinScreenState extends State<SetPinScreen> {
  String _pin = '';
  String? _first;
  String? _error;

  void _press(String d) {
    if (_pin.length >= kPinLength) return;
    HapticFeedback.selectionClick();
    setState(() {
      _pin += d;
      _error = null;
    });
    if (_pin.length < kPinLength) return;

    if (widget.verifyOnly) {
      if (Repo.instance.checkPin(_pin)) {
        Navigator.pop(context, true);
      } else {
        setState(() {
          _pin = '';
          _error = 'PIN salah';
        });
      }
      return;
    }
    if (_first == null) {
      setState(() {
        _first = _pin;
        _pin = '';
      });
    } else if (_first == _pin) {
      Navigator.pop(context, _pin);
    } else {
      setState(() {
        _first = null;
        _pin = '';
        _error = 'PIN tidak sama, ulangi dari awal';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.verifyOnly
        ? 'Masukkan PIN saat ini'
        : _first == null
            ? 'Buat PIN 4 angka'
            : 'Ulangi PIN';
    return Scaffold(
      appBar: AppBar(),
      body: PinPad(
        title: title,
        subtitle: _error ??
            (widget.verifyOnly
                ? 'Untuk mematikan kunci aplikasi'
                : 'PIN diminta setiap membuka LanggananKu'),
        error: _error != null,
        length: _pin.length,
        onDigit: _press,
        onDelete: () => setState(() => _pin = _pin.isEmpty ? '' : _pin.substring(0, _pin.length - 1)),
      ),
    );
  }
}
