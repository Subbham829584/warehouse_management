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

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  Future<void> _quickStockDialog(
    BuildContext context, {
    required MovementType type,
    required List<ProductItem> items,
  }) async {
    if (items.isEmpty) {
      showMessage(context, 'No products available. Add a product first.', error: true);
      return;
    }

    ProductItem selectedItem = items.first;
    final qtyCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    final title = type == MovementType.stockIn ? 'Quick Stock In (Receive)' : 'Quick Stock Out (Dispatch)';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(
                  type == MovementType.stockIn ? Icons.add_circle_outline : Icons.remove_circle_outline,
                  color: type == MovementType.stockIn ? const Color(0xff2e9e6b) : const Color(0xffe75757),
                ),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontSize: 18)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Select Product', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<ProductItem>(
                    value: selectedItem,
                    isExpanded: true,
                    items: items.map((i) {
                      return DropdownMenuItem<ProductItem>(
                        value: i,
                        child: Text(
                          '${i.product.name} (Qty: ${i.product.quantity})',
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => selectedItem = val);
                      }
                    },
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: qtyCtrl,
                    keyboardType: TextInputType.number,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: type == MovementType.stockIn ? 'Quantity to Add' : 'Quantity to Dispatch',
                      helperText: 'Available shelf stock: ${selectedItem.product.quantity} ${selectedItem.product.unit}',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: noteCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Reference / Note (Optional)',
                      hintText: 'e.g. PO-501 or Delivery Note',
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: type == MovementType.stockIn ? const Color(0xff2e9e6b) : const Color(0xffe75757),
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Confirm'),
              ),
            ],
          );
        },
      ),
    );

    if (confirmed != true) return;
    final qty = int.tryParse(qtyCtrl.text.trim());
    if (qty == null || qty <= 0) {
      if (context.mounted) showMessage(context, 'Enter a valid quantity greater than 0', error: true);
      return;
    }

    final scope = AppScope.of(context);
    try {
      await scope.repo.adjustStock(
        productId: selectedItem.id,
        type: type,
        amount: qty,
        userEmail: scope.userEmail,
        note: noteCtrl.text.trim(),
      );
      if (context.mounted) {
        showMessage(context, 'Successfully logged $type of $qty ${selectedItem.product.unit}');
      }
    } catch (e) {
      if (context.mounted) {
        showMessage(context, '$e'.replaceFirst('Bad state: ', ''), error: true);
      }
    }
  }

  Future<void> _quickAddGroup(BuildContext context) async {
    final repo = AppScope.of(context).repo;
    final ctrl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Product Group'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: 'e.g. Fasteners & Tools'),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, ctrl.text), child: const Text('Create')),
        ],
      ),
    );
    ctrl.dispose();
    if (name == null || name.trim().isEmpty) return;

    try {
      final ok = await repo.addGroup(name);
      if (context.mounted) {
        showMessage(context, ok ? 'Group "$name" created' : 'Group "$name" already exists', error: !ok);
      }
    } catch (e) {
      if (context.mounted) showMessage(context, 'Failed: $e', error: true);
    }
  }

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
        final cols = width > 1100 ? 4 : width > 650 ? 2 : 2;

        final inStockCount = items.length - s.lowStock.length - s.outOfStock.length;
        final totalCount = items.isEmpty ? 1 : items.length;
        final inStockPct = (inStockCount / totalCount).clamp(0.0, 1.0);
        final lowStockPct = (s.lowStock.length / totalCount).clamp(0.0, 1.0);
        final outStockPct = (s.outOfStock.length / totalCount).clamp(0.0, 1.0);

        final userName = scope.userEmail.isNotEmpty && scope.userEmail.contains('@')
            ? scope.userEmail.split('@').first
            : 'Manager';

        final reorderCandidates = items
            .where((p) => p.product.quantity <= p.product.minStock)
            .toList();

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            // Standard Inventory Cards
            GridView.count(
              crossAxisCount: cols,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: width > 900 ? 2.6 : 1.95,
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
                  label: 'Needs Attention',
                  value: '${s.lowStock.length + s.outOfStock.length}',
                  subtitle: s.outOfStock.isNotEmpty ? '${s.outOfStock.length} Out of stock' : 'Stock levels healthy',
                  icon: Icons.warning_amber_rounded,
                  color: (s.lowStock.isEmpty && s.outOfStock.isEmpty)
                      ? const Color(0xff2e9e6b)
                      : const Color(0xffe8a317),
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
            const SizedBox(height: 16),

            // 7. Export & Quick Sharing Card
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.copy_all, size: 18),
                        label: const Text('Export CSV to Clipboard'),
                        onPressed: () async {
                          await Clipboard.setData(
                            ClipboardData(text: ExportService.productsCsv(items)),
                          );
                          if (context.mounted) {
                            showMessage(context, 'Full inventory CSV copied to clipboard!');
                          }
                        },
                      ),
                    ),
                    if (s.lowStock.isNotEmpty || s.outOfStock.isNotEmpty) ...[
                      const SizedBox(width: 10),
                      FilledButton.tonalIcon(
                        icon: const Icon(Icons.assignment_outlined, size: 18),
                        label: const Text('Reorder List'),
                        onPressed: () async {
                          await Clipboard.setData(
                            ClipboardData(text: ExportService.productsCsv([...s.outOfStock, ...s.lowStock])),
                          );
                          if (context.mounted) {
                            showMessage(context, 'Reorder alert list copied to clipboard!');
                          }
                        },
                      ),
                    ],
                  ],
                ),
              ),
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

class _QuickButton extends StatelessWidget {
  const _QuickButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: ColorPalette.timberGreen,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HealthLegend extends StatelessWidget {
  const _HealthLegend({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          '$label: $count',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: ColorPalette.timberGreen.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Card(
        elevation: 1.5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18, color: ColorPalette.pacificBlue),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: ColorPalette.timberGreen,),),),
            ],),
            const SizedBox(height: 8),
            child,
          ],),
        ),
      );
}
