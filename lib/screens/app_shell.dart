import 'package:flutter/material.dart';
import 'package:warehouse_management/core/app_scope.dart';
import 'package:warehouse_management/core/ui.dart';
import 'package:warehouse_management/screens/dashboard_page.dart';
import 'package:warehouse_management/screens/groups_page.dart';
import 'package:warehouse_management/screens/movements_page.dart';
import 'package:warehouse_management/screens/scanner_page.dart';
import 'package:warehouse_management/screens/search_page.dart';

/// Bottom-navigation shell: Dashboard · Inventory · Activity.
class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.onSignOut});
  final Future<void> Function() onSignOut;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  static const _titles = ['Dashboard', 'Inventory', 'Activity'];

  Future<void> _logout() async {
    final ok =
        await confirm(context, title: 'Sign out?', confirmLabel: 'Sign out');
    if (ok) await widget.onSignOut();
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final pages = [
      const DashboardPage(),
      const GroupsPage(),
      const MovementsPage(),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_index]),
        actions: [
          IconButton(
            tooltip: 'Search',
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const SearchPage())),
          ),
          IconButton(
            tooltip: 'Scan barcode',
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const ScannerPage())),
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'logout') _logout();
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                enabled: false,
                child: Text(scope.isDemo ? 'Demo mode' : scope.userEmail,
                    style: const TextStyle(fontSize: 12)),
              ),
              const PopupMenuItem(value: 'logout', child: Text('Sign out')),
            ],
          ),
        ],
      ),
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: 'Dashboard'),
          NavigationDestination(
              icon: Icon(Icons.inventory_2_outlined),
              selectedIcon: Icon(Icons.inventory_2),
              label: 'Inventory'),
          NavigationDestination(icon: Icon(Icons.history), label: 'Activity'),
        ],
      ),
    );
  }
}
