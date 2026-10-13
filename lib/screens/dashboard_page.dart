import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:warehouse_management/core/app_scope.dart';
import 'package:warehouse_management/core/formatters.dart';
import 'package:warehouse_management/core/ui.dart';
import 'package:warehouse_management/models/grn.dart';
import 'package:warehouse_management/models/inventory_stats.dart';
import 'package:warehouse_management/models/product.dart';
import 'package:warehouse_management/screens/cycle_count/cycle_count_page.dart';
import 'package:warehouse_management/screens/grn/grn_page.dart';
import 'package:warehouse_management/screens/low_stock_page.dart';
import 'package:warehouse_management/screens/notifications/notifications_page.dart';
import 'package:warehouse_management/screens/pick_list/pick_list_page.dart';
import 'package:warehouse_management/screens/roles/roles_page.dart';
import 'package:warehouse_management/screens/traceability/traceability_page.dart';
import 'package:warehouse_management/screens/transfers/stock_transfer_page.dart';
import 'package:warehouse_management/services/export_service.dart';
import 'package:warehouse_management/services/wms_service.dart';
import 'package:warehouse_management/utils/color_palette.dart';
import 'package:warehouse_management/widgets/bar_list.dart';
import 'package:warehouse_management/widgets/empty_state.dart';
import 'package:warehouse_management/widgets/stat_card.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = AppScope.of(context).repo;
    final wms = WmsService.instance;

    return StreamBuilder<List<ProductItem>>(
      stream: repo.watchProducts(),
      builder: (context, snap) {
        if (snap.hasError) return ErrorState(snap.error);
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = snap.data!;
        if (items.isEmpty) {
          return const EmptyState(
            icon: Icons.inventory_2_outlined,
            title: 'No products yet',
            subtitle: 'Open Inventory, create a group and add your first product.',
          );
        }

        // Initialize WMS demo seed data on first load
        wms.seedDemo(items);
        wms.checkAndGenerateNotifications(items);

        final s = InventoryStats.from(items);
        final width = MediaQuery.of(context).size.width;
        final cols = width > 900 ? 4 : 2;

        final reorderCandidates = items
            .where((p) => p.product.quantity <= p.product.minStock)
            .toList();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Standard Inventory Cards
            GridView.count(
              crossAxisCount: cols,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: width > 900 ? 2.6 : 2.0,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                StatCard(
                  label: 'Products',
                  value: '${s.totalProducts}',
                  icon: Icons.category_outlined,
                ),
                StatCard(
                  label: 'Units in stock',
                  value: '${s.totalUnits}',
                  icon: Icons.layers_outlined,
                  color: ColorPalette.nileBlue,
                ),
                StatCard(
                  label: 'Inventory value',
                  value: Fmt.moneyCompact(s.totalValue),
                  icon: Icons.currency_rupee,
                  color: const Color(0xff2e9e6b),
                ),
                StatCard(
                  label: 'Needs attention',
                  value: '${s.lowStock.length + s.outOfStock.length}',
                  icon: Icons.warning_amber_rounded,
                  color: const Color(0xffe8a317),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LowStockPage()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // WMS Operations Hub
            _buildWmsHub(context),
            const SizedBox(height: 18),

            // Live Warehouse KPIs
            _buildWarehouseKpis(context),
            const SizedBox(height: 18),

            // Reorder Point & Auto-Suggest PO
            _buildReorderSuggestions(context, reorderCandidates),
            const SizedBox(height: 18),

            // Analytical charts
            _Section(
              title: 'Value by group',
              child: BarList(data: s.valueByGroup, format: Fmt.moneyCompact),
            ),
            const SizedBox(height: 16),
            _Section(
              title: 'Units by location',
              child: BarList(
                data: s.unitsByLocation.map((k, v) => MapEntry(k, v.toDouble())),
                format: (v) => v.toInt().toString(),
              ),
            ),
            const SizedBox(height: 16),

            OutlinedButton.icon(
              icon: const Icon(Icons.download),
              label: const Text('Export inventory (copy CSV)'),
              onPressed: () async {
                await Clipboard.setData(
                  ClipboardData(text: ExportService.productsCsv(items)),
                );
                if (context.mounted) {
                  showMessage(context, 'CSV copied. Paste into Excel / Google Sheets.');
                }
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildWmsHub(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.hub_outlined, color: ColorPalette.nileBlue, size: 20),
                SizedBox(width: 8),
                Text(
                  'Warehouse Operations Hub',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: ColorPalette.timberGreen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'End-to-end WMS workflows with put-away & audit controls',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _hubBtn(
                  context,
                  icon: Icons.receipt_long,
                  label: 'Receive PO (GRN)',
                  subtitle: 'Put-Away & Check',
                  color: Colors.blue.shade700,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GrnPage())),
                ),
                _hubBtn(
                  context,
                  icon: Icons.checklist_rtl,
                  label: 'Cycle Counting',
                  subtitle: 'ABC Variance Audit',
                  color: Colors.teal.shade700,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CycleCountPage())),
                ),
                _hubBtn(
                  context,
                  icon: Icons.route,
                  label: 'Wave & Zone Pick',
                  subtitle: 'Bin Walk Paths',
                  color: Colors.indigo.shade700,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PickListPage())),
                ),
                _hubBtn(
                  context,
                  icon: Icons.swap_horiz,
                  label: 'Bin Transfer',
                  subtitle: 'Zone Relocation',
                  color: Colors.purple.shade700,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StockTransferPage())),
                ),
                _hubBtn(
                  context,
                  icon: Icons.timeline,
                  label: 'Traceability',
                  subtitle: 'Lot & Serial Audit',
                  color: Colors.deepOrange.shade700,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TraceabilityPage())),
                ),
                _hubBtn(
                  context,
                  icon: Icons.security,
                  label: 'Roles & RBAC',
                  subtitle: 'Admin / Manager / Picker',
                  color: Colors.brown.shade700,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RolesPage())),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _hubBtn(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final width = (MediaQuery.of(context).size.width - 64) / 2;

    return SizedBox(
      width: width.clamp(140.0, 220.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: color,
                    child: Icon(icon, size: 16, color: Colors.white),
                  ),
                  Icon(Icons.arrow_forward_ios, size: 12, color: color),
                ],
              ),
              const SizedBox(height: 8),
              Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color)),
              Text(subtitle, style: const TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWarehouseKpis(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.speed, color: Color(0xff2e9e6b), size: 20),
                SizedBox(width: 8),
                Text(
                  'Warehouse Operational KPIs',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: ColorPalette.timberGreen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Real-time throughput, velocity, and audit compliance metrics',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _kpiBox('Dock-to-Stock', '1.8 hrs', 'Target < 4h', Colors.blue, Icons.timer_outlined),
                const SizedBox(width: 8),
                _kpiBox('Pick Velocity', '48.5 l/h', '+12% vs goal', Colors.teal, Icons.directions_run),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _kpiBox('Count Coverage', '94.2%', 'Class A items', Colors.orange, Icons.fact_check),
                const SizedBox(width: 8),
                _kpiBox('Put-Away Accuracy', '99.4%', 'Target 99%', Colors.green, Icons.verified),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _kpiBox(String title, String value, String sub, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: color.withValues(alpha: 0.2),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600)),
                  Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
                  Text(sub, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReorderSuggestions(BuildContext context, List<ProductItem> lowItems) {
    if (lowItems.isEmpty) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.add_shopping_cart, color: Colors.deepOrange, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Auto-Suggested Purchase Orders',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: ColorPalette.timberGreen,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    '${lowItems.length} Low Stock',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red.shade800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Stock fell below safety reorder point. Suggested quantities based on minimum buffer.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            for (final item in lowItems.take(3))
              _reorderItemTile(context, item),
          ],
        ),
      ),
    );
  }

  Widget _reorderItemTile(BuildContext context, ProductItem p) {
    final cur = p.product.quantity;
    final min = p.product.minStock;
    final suggestedQty = (min * 2) - cur > 0 ? (min * 2) - cur : 10;
    final estCost = suggestedQty * p.product.cost;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text('Current: $cur | Min buffer: $min', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                const SizedBox(height: 4),
                Text(
                  'Suggested PO: $suggestedQty units (${Fmt.money(estCost)})',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: ColorPalette.nileBlue),
                ),
              ],
            ),
          ),
          FilledButton.tonal(
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              visualDensity: VisualDensity.compact,
            ),
            onPressed: () {
              final newGrn = GoodsReceivedNote(
                id: 'grn_${DateTime.now().millisecondsSinceEpoch}',
                grnNumber: 'GRN-2026-${(DateTime.now().millisecondsSinceEpoch % 1000).toString().padLeft(3, '0')}',
                poId: 'PO-AUTO-${(DateTime.now().millisecondsSinceEpoch % 1000).toString().padLeft(3, '0')}',
                poNumber: 'PO-AUTO-${(DateTime.now().millisecondsSinceEpoch % 1000).toString().padLeft(3, '0')}',
                supplierId: 'supp_1',
                supplierName: p.product.company.isNotEmpty ? p.product.company : 'Primary Supplier',
                receivedBy: AppScope.of(context).userEmail,
                receivedAt: DateTime.now(),
                status: GrnStatus.draft,
                items: [
                  GrnLineItem(
                    productId: p.id,
                    productName: p.product.name,
                    sku: p.product.sku,
                    orderedQty: suggestedQty,
                    receivedQty: suggestedQty,
                    putAwayBin: p.product.location.isNotEmpty ? p.product.location : 'A-01-S1',
                    lotNumber: 'LOT-2026-${p.id.substring(0, p.id.length > 4 ? 4 : p.id.length).toUpperCase()}',
                  ),
                ],
              );
              WmsService.instance.createGrn(newGrn);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Auto-generated PO & Draft GRN for ${p.product.name}'),
                  action: SnackBarAction(
                    label: 'Open GRN',
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GrnPage())),
                  ),
                ),
              );
            },
            child: const Text('Create PO', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child, this.trailing});
  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                  child: Text(title,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: ColorPalette.timberGreen))),
              if (trailing != null) trailing!,
            ]),
            const SizedBox(height: 8),
            child,
          ]),
        ),
      );
}
