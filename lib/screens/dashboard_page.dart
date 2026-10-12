import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:warehouse_management/core/app_scope.dart';
import 'package:warehouse_management/core/formatters.dart';
import 'package:warehouse_management/core/ui.dart';
import 'package:warehouse_management/models/inventory_stats.dart';
import 'package:warehouse_management/models/product.dart';
import 'package:warehouse_management/models/stock_movement.dart';
import 'package:warehouse_management/screens/low_stock_page.dart';
import 'package:warehouse_management/screens/product_details_page.dart';
import 'package:warehouse_management/screens/product_form_page.dart';
import 'package:warehouse_management/services/export_service.dart';
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
    final scope = AppScope.of(context);
    final repo = scope.repo;

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
            subtitle: 'Open Inventory, create a group, and add your first product.',
          );
        }

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

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            // 1. Executive Welcome & Status Banner
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      ColorPalette.pacificBlue.withValues(alpha: 0.14),
                      ColorPalette.white,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_greeting()}, ${userName[0].toUpperCase()}${userName.substring(1)} 👋',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: ColorPalette.timberGreen,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Godown 1 & 2 • Live Inventory Command Hub',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: ColorPalette.timberGreen.withValues(alpha: 0.65),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: scope.isDemo
                                ? Colors.orange.withValues(alpha: 0.15)
                                : const Color(0xff2e9e6b).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.circle,
                                size: 8,
                                color: scope.isDemo ? Colors.orange : const Color(0xff2e9e6b),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                scope.isDemo ? 'Demo Mode' : 'Cloud Sync',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: scope.isDemo ? Colors.orange.shade800 : const Color(0xff2e9e6b),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Quick Action Shortcuts Bar
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _QuickButton(
                            icon: Icons.add,
                            label: 'Stock In',
                            color: const Color(0xff2e9e6b),
                            onTap: () => _quickStockDialog(context, type: MovementType.stockIn, items: items),
                          ),
                          const SizedBox(width: 8),
                          _QuickButton(
                            icon: Icons.remove,
                            label: 'Stock Out',
                            color: const Color(0xffe75757),
                            onTap: () => _quickStockDialog(context, type: MovementType.stockOut, items: items),
                          ),
                          const SizedBox(width: 8),
                          _QuickButton(
                            icon: Icons.add_box_outlined,
                            label: 'New Product',
                            color: ColorPalette.pacificBlue,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const ProductFormPage()),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _QuickButton(
                            icon: Icons.create_new_folder_outlined,
                            label: 'New Group',
                            color: ColorPalette.nileBlue,
                            onTap: () => _quickAddGroup(context),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 2. Primary KPI Stat Cards
            GridView.count(
              crossAxisCount: cols,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: width > 900 ? 2.6 : 1.95,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                StatCard(
                  label: 'Catalog Products',
                  value: '${s.totalProducts}',
                  subtitle: '${s.valueByGroup.length} Categories',
                  icon: Icons.category_outlined,
                  color: ColorPalette.pacificBlue,
                ),
                StatCard(
                  label: 'Units In Stock',
                  value: '${s.totalUnits}',
                  subtitle: '${s.unitsByLocation.length} Storage Godowns',
                  icon: Icons.layers_outlined,
                  color: ColorPalette.nileBlue,
                ),
                StatCard(
                  label: 'Inventory Value',
                  value: Fmt.moneyCompact(s.totalValue),
                  subtitle: 'Total Assets in ₹',
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
            const SizedBox(height: 16),

            // 3. Stock Health Meter Card
            Card(
              elevation: 1.5,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.health_and_safety_outlined, size: 20, color: ColorPalette.pacificBlue),
                        const SizedBox(width: 8),
                        const Text(
                          'Stock Health Distribution',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: ColorPalette.timberGreen,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${((inStockCount / totalCount) * 100).toInt()}% Optimum',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xff2e9e6b),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // Multi-segmented bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        height: 10,
                        child: Row(
                          children: [
                            if (inStockPct > 0)
                              Expanded(
                                flex: (inStockPct * 100).toInt(),
                                child: Container(color: const Color(0xff2e9e6b)),
                              ),
                            if (lowStockPct > 0)
                              Expanded(
                                flex: (lowStockPct * 100).toInt(),
                                child: Container(color: const Color(0xffe8a317)),
                              ),
                            if (outStockPct > 0)
                              Expanded(
                                flex: (outStockPct * 100).toInt(),
                                child: Container(color: const Color(0xffe75757)),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _HealthLegend(
                          label: 'Healthy Stock',
                          count: inStockCount,
                          color: const Color(0xff2e9e6b),
                        ),
                        _HealthLegend(
                          label: 'Low Stock Alert',
                          count: s.lowStock.length,
                          color: const Color(0xffe8a317),
                        ),
                        _HealthLegend(
                          label: 'Depleted / Out',
                          count: s.outOfStock.length,
                          color: const Color(0xffe75757),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 4. Breakdown by Category & Location
            if (width > 850)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _Section(
                      title: 'Value by Category',
                      icon: Icons.pie_chart_outline,
                      child: BarList(
                        data: s.valueByGroup,
                        format: Fmt.moneyCompact,
                        barColor: ColorPalette.pacificBlue,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _Section(
                      title: 'Units by Location',
                      icon: Icons.warehouse_outlined,
                      child: BarList(
                        data: s.unitsByLocation.map((k, v) => MapEntry(k, v.toDouble())),
                        format: (v) => '${v.toInt()} units',
                        barColor: const Color(0xff2e9e6b),
                      ),
                    ),
                  ),
                ],
              )
            else ...[
              _Section(
                title: 'Value by Category',
                icon: Icons.pie_chart_outline,
                child: BarList(
                  data: s.valueByGroup,
                  format: Fmt.moneyCompact,
                  barColor: ColorPalette.pacificBlue,
                ),
              ),
              const SizedBox(height: 14),
              _Section(
                title: 'Units by Location',
                icon: Icons.warehouse_outlined,
                child: BarList(
                  data: s.unitsByLocation.map((k, v) => MapEntry(k, v.toDouble())),
                  format: (v) => '${v.toInt()} units',
                  barColor: const Color(0xff2e9e6b),
                ),
              ),
            ],
            const SizedBox(height: 16),

            // 5. Urgent Restock Needed Section
            if (s.lowStock.isNotEmpty || s.outOfStock.isNotEmpty)
              _Section(
                title: 'Needs Immediate Restock',
                icon: Icons.notification_important_outlined,
                trailing: TextButton.icon(
                  icon: const Icon(Icons.arrow_forward, size: 16),
                  label: const Text('View All'),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LowStockPage()),
                  ),
                ),
                child: Column(
                  children: [
                    for (final i in [...s.outOfStock, ...s.lowStock].take(4))
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          radius: 18,
                          backgroundColor: i.product.isOutOfStock
                              ? const Color(0xffe75757).withValues(alpha: 0.15)
                              : const Color(0xffe8a317).withValues(alpha: 0.15),
                          child: Icon(
                            i.product.isOutOfStock ? Icons.error_outline : Icons.warning_amber_rounded,
                            size: 20,
                            color: i.product.isOutOfStock ? const Color(0xffe75757) : const Color(0xffe8a317),
                          ),
                        ),
                        title: Text(
                          i.product.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text('${i.product.location} • Min ${i.product.minStock} ${i.product.unit}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${i.product.quantity} ${i.product.unit}',
                              style: TextStyle(
                                color: i.product.isOutOfStock ? const Color(0xffe75757) : const Color(0xffe8a317),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.add_shopping_cart, size: 20, color: ColorPalette.pacificBlue),
                              tooltip: 'Quick Restock',
                              onPressed: () => _quickStockDialog(context, type: MovementType.stockIn, items: [i]),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 16),

            // 6. Live Recent Operations Feed
            StreamBuilder<List<StockMovement>>(
              stream: repo.watchMovements(limit: 4),
              builder: (context, mSnap) {
                final moves = mSnap.data ?? [];
                if (moves.isEmpty) return const SizedBox();
                return _Section(
                  title: 'Recent Warehouse Operations',
                  icon: Icons.history,
                  child: Column(
                    children: [
                      for (final m in moves) MovementTile(m),
                    ],
                  ),
                );
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
  const _Section({
    required this.title,
    required this.child,
    this.icon,
    this.trailing,
  });

  final String title;
  final Widget child;
  final IconData? icon;
  final Widget? trailing;

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
                        color: ColorPalette.timberGreen,
                      ),
                    ),
                  ),
                  if (trailing != null) trailing!,
                ],
              ),
              const SizedBox(height: 12),
              child,
            ],
          ),
        ),
      );
}
