import 'package:flutter/material.dart';

import '../services/notification_service.dart';
import '../services/repository.dart';
import '../theme/app_theme.dart';
import 'scan_screen.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  Future<void> _start(BuildContext context, {required bool scan}) async {
    await NotificationService.requestPermission();
    final nav = Navigator.of(context);
    // Layar utama tampil otomatis setelah onboarding selesai (lihat AppRoot).
    await Repo.instance.completeOnboarding();
    if (scan) {
      nav.push(MaterialPageRoute(builder: (_) => const ScanScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget point(IconData icon, String title, String body) => Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.line),
              ),
              child: Icon(icon, color: AppColors.lime, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15.5)),
                const SizedBox(height: 3),
                Text(body, style: TextStyle(color: AppColors.muted, height: 1.4)),
              ]),
            ),
          ]),
        );

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                  color: AppColors.lime, borderRadius: BorderRadius.circular(18)),
              child: Icon(Icons.autorenew_rounded, size: 30, color: AppColors.onLime),
            ),
            const SizedBox(height: 28),
            Text.rich(
              TextSpan(children: [
                TextSpan(text: 'Semua tagihan\nberulang, '),
                TextSpan(text: 'terkendali.', style: TextStyle(color: AppColors.accentText)),
              ]),
              style: TextStyle(
                  fontSize: 34, fontWeight: FontWeight.w800, height: 1.15, letterSpacing: -0.8),
            ),
            const SizedBox(height: 12),
            Text('LanggananKu menemukan langganan Anda, mengingatkan sebelum ditagih, '
                'dan membantu berhenti membayar yang tidak terpakai.',
                style: TextStyle(color: AppColors.muted, fontSize: 15, height: 1.45)),
            const SizedBox(height: 30),
            point(Icons.document_scanner_outlined, 'Deteksi otomatis',
                'Dari SMS bank/e-wallet (Android) atau email nota yang Anda tempel.'),
            point(Icons.notifications_active_outlined, 'Pengingat H-3 & H-1',
                'Tidak ada lagi tagihan yang lewat tanpa disadari.'),
            point(Icons.lock_outline_rounded, 'Data tetap di HP Anda',
                'Tanpa akun dan tanpa server. Semua diproses di perangkat.'),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => _start(context, scan: true),
                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 18)),
                child: const Text('Mulai & pindai tagihan'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => _start(context, scan: false),
                style: TextButton.styleFrom(foregroundColor: AppColors.muted),
                child: const Text('Nanti saja, isi manual'),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
