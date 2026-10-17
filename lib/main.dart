import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'screens/home_shell.dart';
import 'screens/onboarding_screen.dart';
import 'services/notification_service.dart';
import 'services/repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID');
  await NotificationService.init();
  await Repo.instance.load();
  runApp(const LanggananKuApp());
}

const Color kBrand = Color(0xFF0F766E);

class LanggananKuApp extends StatelessWidget {
  const LanggananKuApp({super.key});

  ThemeData _theme(Brightness b) {
    final scheme = ColorScheme.fromSeed(seedColor: kBrand, brightness: b);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LanggananKu',
      debugShowCheckedModeBanner: false,
      theme: _theme(Brightness.light),
      darkTheme: _theme(Brightness.dark),
      locale: const Locale('id', 'ID'),
      supportedLocales: const [Locale('id', 'ID'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Repo.instance.onboarded ? const HomeShell() : const OnboardingScreen(),
    );
  }
}
