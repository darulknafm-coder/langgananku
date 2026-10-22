import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'catalog_picker.dart';
import 'dashboard_screen.dart';
import 'savings_screen.dart';
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
        decoration: BoxDecoration(
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

/// Mulai menambah langganan: langsung ke layar pilih layanan.
Future<void> showAddSheet(BuildContext context) =>
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CatalogPicker()));
