import 'package:flutter/material.dart';

import '../services/notification_service.dart';
import '../services/repository.dart';
import 'home_shell.dart';
import 'scan_screen.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  Future<void> _start(BuildContext context, {required bool scan}) async {
    await NotificationService.requestPermission();
    await Repo.instance.completeOnboarding();
    if (!context.mounted) return;
    final nav = Navigator.of(context);
    nav.pushReplacement(MaterialPageRoute(builder: (_) => const HomeShell()));
    if (scan) {
      nav.push(MaterialPageRoute(builder: (_) => const ScanScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    Widget point(IconData icon, String title, String body) => Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: cs.primaryContainer, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: cs.onPrimaryContainer),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(body, style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
              ]),
            ),
          ]),
        );

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.autorenew_rounded, size: 48, color: cs.primary),
            const SizedBox(height: 16),
            Text('LanggananKu',
                style: tt.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text('Kendali penuh atas semua tagihan berulang Anda.',
                style: tt.titleMedium?.copyWith(color: cs.onSurfaceVariant)),
            const SizedBox(height: 32),
            point(Icons.document_scanner_outlined, 'Deteksi otomatis',
                'Temukan langganan dari SMS bank/e-wallet (Android) atau email nota yang Anda tempel.'),
            point(Icons.notifications_active_outlined, 'Pengingat H-3 & H-1',
                'Tidak ada lagi tagihan yang lewat tanpa disadari.'),
            point(Icons.trending_up_rounded, 'Peringatan kenaikan harga',
                'Tahu saat harga naik diam-diam, lalu batalkan dengan sekali ketuk.'),
            point(Icons.lock_outline_rounded, 'Data tetap di HP Anda',
                'Pemindaian dilakukan di perangkat. Tanpa akun, tanpa server.'),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _start(context, scan: true),
                icon: const Icon(Icons.search_rounded),
                label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Text('Izinkan notifikasi & pindai tagihan')),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => _start(context, scan: false),
                child: const Text('Nanti saja, saya isi manual'),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
