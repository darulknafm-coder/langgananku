import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardScreen(onSeeAll: () => setState(() => _index = 1)),
      const SubscriptionsScreen(),
      const SavingsScreen(),
      const SettingsScreen(),
    ];
    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      floatingActionButton: _index <= 1
          ? FloatingActionButton.extended(
              onPressed: () => showAddSheet(context),
              icon: const Icon(Icons.add),
              label: const Text('Tambah'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Beranda'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Langganan'),
          NavigationDestination(icon: Icon(Icons.savings_outlined), selectedIcon: Icon(Icons.savings), label: 'Hemat'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Setelan'),
        ],
      ),
    );
  }
}

Future<void> showAddSheet(BuildContext context) {
  void go(Widget page) {
    Navigator.of(context).pop();
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  return showModalBottomSheet(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(
          leading: const Icon(Icons.grid_view_rounded),
          title: const Text('Pilih dari katalog'),
          subtitle: const Text('Netflix, Spotify, ChatGPT, IndiHome, dll.'),
          onTap: () => go(const CatalogPicker()),
        ),
        ListTile(
          leading: const Icon(Icons.document_scanner_outlined),
          title: const Text('Pindai SMS / email nota'),
          subtitle: const Text('Deteksi otomatis tagihan berulang'),
          onTap: () => go(const ScanScreen()),
        ),
        ListTile(
          leading: const Icon(Icons.edit_outlined),
          title: const Text('Isi manual'),
          onTap: () => go(const EditScreen()),
        ),
        const SizedBox(height: 12),
      ]),
    ),
  );
}
