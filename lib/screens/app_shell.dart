import 'package:flutter/material.dart';
import 'package:warehouse_management/core/app_scope.dart';
import 'package:warehouse_management/core/ui.dart';
import 'package:warehouse_management/screens/analytics/analytics_page.dart';
import 'package:warehouse_management/screens/audit/stock_audit_page.dart';
import 'package:warehouse_management/screens/dashboard_page.dart';
import 'package:warehouse_management/screens/dispatch/dispatch_page.dart';
import 'package:warehouse_management/screens/groups_page.dart';
import 'package:warehouse_management/screens/layout/warehouse_layout_page.dart';
import 'package:warehouse_management/screens/movements_page.dart';
import 'package:warehouse_management/screens/procurement/procurement_page.dart';
import 'package:warehouse_management/screens/scanner_page.dart';
import 'package:warehouse_management/screens/search_page.dart';
import 'package:warehouse_management/services/enterprise_store.dart';
import 'package:warehouse_management/utils/color_palette.dart';

/// Master Enterprise Shell providing navigation across all 8 core warehouse modules:
/// Dashboard, Inventory, Procurement & POs, Dispatch & Orders, Visual Zones, Cycle Count Audit, ABC Analytics, Activity.
class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.onSignOut});
  final Future<void> Function() onSignOut;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;
  final _store = EnterpriseStore.instance;

  static const _titles = [
    'Dashboard',
    'Inventory Catalog',
    'Procurement & POs',
    'Outbound Dispatch',
    'Warehouse Zones & Bins',
    'Cycle Count Audit',
    'ABC Analytics & Forecast',
    'Movement Activity',
  ];

  @override
  void initState() {
    super.initState();
    _store.addListener(_onStoreUpdate);
  }

  void _onStoreUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _store.removeListener(_onStoreUpdate);
    super.dispose();
  }

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
      const ProcurementPage(),
      const DispatchPage(),
      const WarehouseLayoutPage(),
      const StockAuditPage(),
      const AnalyticsPage(),
      const MovementsPage(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _titles[_index],
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 19),
        ),
        actions: [
          IconButton(
            tooltip: 'Search products',
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
            tooltip: 'Account',
            onSelected: (v) {
              if (v == 'logout') _logout();
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                enabled: false,
                child: Row(
                  children: [
                    const Icon(Icons.account_circle_outlined, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        scope.isDemo ? 'Demo Mode' : scope.userEmail,
                        style: const TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 16, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Sign out', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      drawer: _buildEnterpriseDrawer(context, scope),
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index > 3 ? 0 : _index,
        onDestinationSelected: (i) {
          if (i == 4) {
            // Open full module drawer
            Scaffold.of(context).openDrawer();
          } else {
            setState(() => _index = i);
          }
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          const NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Inventory',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: _store.pendingPOCount > 0,
              label: Text('${_store.pendingPOCount}'),
              child: const Icon(Icons.receipt_long_outlined),
            ),
            selectedIcon: const Icon(Icons.receipt_long),
            label: 'Procurement',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: _store.pendingDispatchCount > 0,
              label: Text('${_store.pendingDispatchCount}'),
              child: const Icon(Icons.local_shipping_outlined),
            ),
            selectedIcon: const Icon(Icons.local_shipping),
            label: 'Dispatch',
          ),
        ],
      ),
    );
  }

  Widget _buildEnterpriseDrawer(BuildContext context, AppScope scope) {
    return Drawer(
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [ColorPalette.timberGreen, ColorPalette.pacificBlue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.warehouse, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'WMS Enterprise',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        scope.isDemo ? 'Demo Mode Active' : scope.userEmail,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Nav list
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildDrawerSection('CORE MODULES'),
                _buildDrawerTile(
                  title: 'Executive Dashboard',
                  icon: Icons.dashboard_outlined,
                  activeIcon: Icons.dashboard,
                  index: 0,
                ),
                _buildDrawerTile(
                  title: 'Inventory Catalog',
                  icon: Icons.inventory_2_outlined,
                  activeIcon: Icons.inventory_2,
                  index: 1,
                ),
                _buildDrawerSection('SUPPLY CHAIN & LOGISTICS'),
                _buildDrawerTile(
                  title: 'Procurement & Suppliers',
                  icon: Icons.receipt_long_outlined,
                  activeIcon: Icons.receipt_long,
                  index: 2,
                  badgeCount: _store.pendingPOCount,
                ),
                _buildDrawerTile(
                  title: 'Outbound Orders & Dispatch',
                  icon: Icons.local_shipping_outlined,
                  activeIcon: Icons.local_shipping,
                  index: 3,
                  badgeCount: _store.pendingDispatchCount,
                ),
                _buildDrawerSection('WAREHOUSE OPERATIONS'),
                _buildDrawerTile(
                  title: 'Warehouse Zones & Bins',
                  icon: Icons.grid_view_outlined,
                  activeIcon: Icons.grid_view,
                  index: 4,
                ),
                _buildDrawerTile(
                  title: 'Cycle Count & Stock Audit',
                  icon: Icons.fact_check_outlined,
                  activeIcon: Icons.fact_check,
                  index: 5,
                ),
                _buildDrawerSection('INSIGHTS & AUDIT TRAIL'),
                _buildDrawerTile(
                  title: 'ABC Analytics & Forecast',
                  icon: Icons.analytics_outlined,
                  activeIcon: Icons.analytics,
                  index: 6,
                ),
                _buildDrawerTile(
                  title: 'Activity & Movement Log',
                  icon: Icons.history_outlined,
                  activeIcon: Icons.history,
                  index: 7,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Sign out', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              _logout();
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildDrawerSection(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }

  Widget _buildDrawerTile({
    required String title,
    required IconData icon,
    required IconData activeIcon,
    required int index,
    int? badgeCount,
  }) {
    final isSelected = _index == index;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected
            ? ColorPalette.pacificBlue.withValues(alpha: 0.12)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        dense: true,
        leading: Icon(
          isSelected ? activeIcon : icon,
          color: isSelected ? ColorPalette.pacificBlue : Colors.blueGrey.shade700,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? ColorPalette.timberGreen : Colors.black87,
          ),
        ),
        trailing: badgeCount != null && badgeCount > 0
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: ColorPalette.mandy,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$badgeCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : null,
        onTap: () {
          setState(() => _index = index);
          Navigator.pop(context);
        },
      ),
    );
  }
}
