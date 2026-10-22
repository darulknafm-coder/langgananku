import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:firebase_auth/firebase_auth.dart' show User;

import 'screens/auth_screen.dart';
import 'screens/home_shell.dart';
import 'screens/lock_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/notification_service.dart';
import 'services/auth_service.dart';
import 'services/promo_service.dart';
import 'services/sync_service.dart';
import 'services/repository.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    try {
      await initializeDateFormatting('id_ID').timeout(const Duration(seconds: 5));
      await Repo.instance.load().timeout(const Duration(seconds: 8));
      await AuthService.init();
    } catch (e, st) {
      // Tampilkan layar error alih-alih macet di splash screen.
      runApp(_StartupErrorApp(error: e, stack: st));
      return;
    }

    runApp(const LanggananKuApp());

    // Notifikasi disiapkan SETELAH layar pertama tampil, supaya
    // aplikasi tidak pernah tertahan di splash screen.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await NotificationService.init();
      await Repo.instance.refreshReminders();
      unawaited(PromoService.instance.load());
    });
  }, (e, st) {
    debugPrint('Uncaught: $e\n$st');
  });
}

class LanggananKuApp extends StatelessWidget {
  const LanggananKuApp({super.key});

  ThemeMode _mode(String v) => switch (v) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: Repo.instance.themeMode,
      builder: (context, mode, _) => MaterialApp(
        title: 'LanggananKu',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(kLight),
        darkTheme: buildAppTheme(kDark),
        themeMode: _mode(mode),
        themeAnimationDuration: Duration.zero,
        locale: const Locale('id', 'ID'),
        supportedLocales: const [Locale('id', 'ID'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const AppRoot(),
        builder: (context, child) {
          final dark = switch (mode) {
            'light' => false,
            'dark' => true,
            _ => MediaQuery.platformBrightnessOf(context) == Brightness.dark,
          };
          // Warna dipakai langsung oleh layar → atur sebelum layar dibangun,
          // dan bangun ulang semuanya saat tema berganti.
          AppColors.p = dark ? kDark : kLight;
          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
              statusBarBrightness: dark ? Brightness.dark : Brightness.light,
              systemNavigationBarColor: AppColors.surface,
              systemNavigationBarIconBrightness: dark ? Brightness.light : Brightness.dark,
            ),
            child: LockGate(
              child: KeyedSubtree(
                key: ValueKey(dark),
                child: child ?? const SizedBox.shrink(),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Menentukan layar pertama: Masuk/Daftar → (memuat data akun) → Perkenalan → Beranda.
class AppRoot extends StatelessWidget {
  const AppRoot({super.key});

  Widget _afterLogin() => ListenableBuilder(
        listenable: Repo.instance,
        builder: (context, _) =>
            Repo.instance.onboarded ? const HomeShell() : const OnboardingScreen(),
      );

  @override
  Widget build(BuildContext context) {
    if (!AuthService.available) return _afterLogin();
    return StreamBuilder<User?>(
      stream: AuthService.changes,
      initialData: AuthService.user,
      builder: (context, snap) {
        final user = snap.data;
        if (user == null) return const AuthScreen();
        return _SyncGate(key: ValueKey(user.uid), uid: user.uid, child: _afterLogin());
      },
    );
  }
}

/// Mengambil data dari akun sekali setelah login, lalu menampilkan [child].
class _SyncGate extends StatefulWidget {
  final String uid;
  final Widget child;
  const _SyncGate({super.key, required this.uid, required this.child});

  @override
  State<_SyncGate> createState() => _SyncGateState();
}

class _SyncGateState extends State<_SyncGate> {
  late final Future<void> _start = SyncService.start(widget.uid);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _start,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return Scaffold(
            body: Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text('Menyiapkan data akun…', style: TextStyle(color: AppColors.muted)),
              ]),
            ),
          );
        }
        return widget.child;
      },
    );
  }
}

/// Layar darurat bila persiapan awal gagal — berisi pesan error
/// yang bisa di-screenshot untuk perbaikan.
class _StartupErrorApp extends StatelessWidget {
  final Object error;
  final StackTrace stack;
  const _StartupErrorApp({required this.error, required this.stack});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(kDark),
      home: Scaffold(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Icon(Icons.error_outline_rounded, color: AppColors.coral, size: 40),
              const SizedBox(height: 16),
              const Text('LanggananKu gagal dibuka',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text('Screenshot layar ini dan kirimkan ke pengembang.',
                  style: TextStyle(color: AppColors.muted)),
              const SizedBox(height: 20),
              SelectableText('$error\n\n$stack',
                  style: TextStyle(fontSize: 12, color: AppColors.text)),
            ],
          ),
        ),
      ),
    );
  }
}
