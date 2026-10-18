import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'screens/home_shell.dart';
import 'screens/lock_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/notification_service.dart';
import 'services/promo_service.dart';
import 'services/repository.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: AppColors.surface,
      systemNavigationBarIconBrightness: Brightness.light,
    ));

    try {
      await initializeDateFormatting('id_ID').timeout(const Duration(seconds: 5));
      await Repo.instance.load().timeout(const Duration(seconds: 8));
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

  @override
  Widget build(BuildContext context) {
    final theme = buildAppTheme();
    return MaterialApp(
      title: 'LanggananKu',
      debugShowCheckedModeBanner: false,
      theme: theme,
      darkTheme: theme,
      themeMode: ThemeMode.dark,
      locale: const Locale('id', 'ID'),
      supportedLocales: const [Locale('id', 'ID'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Repo.instance.onboarded ? const HomeShell() : const OnboardingScreen(),
      builder: (context, child) => LockGate(child: child ?? const SizedBox.shrink()),
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
      theme: buildAppTheme(),
      home: Scaffold(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Icon(Icons.error_outline_rounded, color: AppColors.coral, size: 40),
              const SizedBox(height: 16),
              const Text('LanggananKu gagal dibuka',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              const Text('Screenshot layar ini dan kirimkan ke pengembang.',
                  style: TextStyle(color: AppColors.muted)),
              const SizedBox(height: 20),
              SelectableText('$error\n\n$stack',
                  style: const TextStyle(fontSize: 12, color: AppColors.text)),
            ],
          ),
        ),
      ),
    );
  }
}
