import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'catalog_picker.dart';
import 'dashboard_screen.dart';
import 'edit_screen.dart';
import 'savings_screen.dart';
import 'scan_screen.dart';
import 'settings_screen.dart';
import 'subscriptions_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  void _go(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardScreen(onSeeAll: () => _go(1), onOpenSavings: () => _go(2)),
      const SubscriptionsScreen(),
      const SavingsScreen(),
      const SettingsScreen(),
    ];
    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      floatingActionButton: _index <= 1
          ? FloatingActionButton.extended(
              onPressed: () => showAddSheet(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Tambah', style: TextStyle(fontWeight: FontWeight.w700)),
            )
          : null,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.line)),
        ),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: _go,
          destinations: const [
            NavigationDestination(
                icon: Icon(Icons.space_dashboard_outlined),
                selectedIcon: Icon(Icons.space_dashboard_rounded),
                label: 'Beranda'),
            NavigationDestination(
                icon: Icon(Icons.layers_outlined),
                selectedIcon: Icon(Icons.layers_rounded),
                label: 'Langganan'),
            NavigationDestination(
                icon: Icon(Icons.savings_outlined),
                selectedIcon: Icon(Icons.savings_rounded),
                label: 'Hemat'),
            NavigationDestination(
                icon: Icon(Icons.tune_outlined),
                selectedIcon: Icon(Icons.tune_rounded),
                label: 'Setelan'),
          ],
        ),
      ),
    );
  }
}

Future<void> showAddSheet(BuildContext context) {
  void go(Widget page) {
    Navigator.of(context).pop();
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  Widget option(IconData icon, String title, String sub, VoidCallback onTap, {bool primary = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: primary ? AppColors.lime : AppColors.surface2,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: primary ? AppColors.onLime.withAlpha(30) : AppColors.surface3,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: primary ? AppColors.onLime : AppColors.lime),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title,
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15.5,
                          color: primary ? AppColors.onLime : AppColors.text)),
                  const SizedBox(height: 2),
                  Text(sub,
                      style: TextStyle(
                          fontSize: 13,
                          color: primary ? AppColors.onLime.withAlpha(180) : AppColors.muted)),
                ]),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: primary ? AppColors.onLime : AppColors.faint),
            ]),
          ),
        ),
      ),
    );
  }

  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Tambah langganan',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          const Text('Pilih cara yang paling cepat untuk Anda.',
              style: TextStyle(color: AppColors.muted)),
          const SizedBox(height: 18),
          option(Icons.document_scanner_rounded, 'Pindai SMS / email nota',
              'Deteksi otomatis tagihan berulang', () => go(const ScanScreen()),
              primary: true),
          option(Icons.grid_view_rounded, 'Pilih dari katalog',
              'Netflix, Spotify, ChatGPT, IndiHome, dll.', () => go(const CatalogPicker())),
          option(Icons.edit_rounded, 'Isi manual', 'Untuk layanan yang tidak ada di katalog',
              () => go(const EditScreen())),
        ]),
      ),
    ),
  );
}
