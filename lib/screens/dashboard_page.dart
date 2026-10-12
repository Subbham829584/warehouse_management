import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:warehouse_management/core/app_scope.dart';
import 'package:warehouse_management/core/formatters.dart';
import 'package:warehouse_management/core/ui.dart';
import 'package:warehouse_management/models/inventory_stats.dart';
import 'package:warehouse_management/models/product.dart';
import 'package:warehouse_management/screens/low_stock_page.dart';
import 'package:warehouse_management/services/export_service.dart';
import 'package:warehouse_management/utils/color_palette.dart';
import 'package:warehouse_management/widgets/bar_list.dart';
import 'package:warehouse_management/widgets/empty_state.dart';
import 'package:warehouse_management/widgets/stat_card.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = AppScope.of(context).repo;
    return StreamBuilder<List<ProductItem>>(
      stream: repo.watchProducts(),
      builder: (context, snap) {
        if (snap.hasError) return ErrorState(snap.error);
        if (!snap.hasData)
          return const Center(child: CircularProgressIndicator());
        final items = snap.data!;
        if (items.isEmpty) {
          return const EmptyState(
              icon: Icons.inventory_2_outlined,
              title: 'No products yet',
              subtitle:
                  'Open Inventory, create a group and add your first product.');
        }
        final s = InventoryStats.from(items);
        final width = MediaQuery.of(context).size.width;
        final cols = width > 900 ? 4 : 2;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
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
                    icon: Icons.category_outlined),
                StatCard(
                    label: 'Units in stock',
                    value: '${s.totalUnits}',
                    icon: Icons.layers_outlined,
                    color: ColorPalette.nileBlue),
                StatCard(
                    label: 'Inventory value',
                    value: Fmt.moneyCompact(s.totalValue),
                    icon: Icons.currency_rupee,
                    color: const Color(0xff2e9e6b)),
                StatCard(
                  label: 'Needs attention',
                  value: '${s.lowStock.length + s.outOfStock.length}',
                  icon: Icons.warning_amber_rounded,
                  color: const Color(0xffe8a317),
                  onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const LowStockPage())),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _Section(
              title: 'Value by group',
              child: BarList(data: s.valueByGroup, format: Fmt.moneyCompact),
            ),
            const SizedBox(height: 16),
            _Section(
              title: 'Units by location',
              child: BarList(
                data:
                    s.unitsByLocation.map((k, v) => MapEntry(k, v.toDouble())),
                format: (v) => v.toInt().toString(),
              ),
            ),
            const SizedBox(height: 16),
            if (s.lowStock.isNotEmpty || s.outOfStock.isNotEmpty)
              _Section(
                title: 'Restock soon',
                trailing: TextButton(
                  onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const LowStockPage())),
                  child: const Text('See all'),
                ),
                child: Column(children: [
                  for (final i in [...s.outOfStock, ...s.lowStock].take(5))
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(i.product.name,
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(i.product.location),
                      trailing: Text(
                          '${i.product.quantity} / min ${i.product.minStock}',
                          style: TextStyle(
                              color: i.product.isOutOfStock
                                  ? const Color(0xffe75757)
                                  : const Color(0xffe8a317),
                              fontWeight: FontWeight.bold)),
                    ),
                ]),
              ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              icon: const Icon(Icons.download),
              label: const Text('Export inventory (copy CSV)'),
              onPressed: () async {
                await Clipboard.setData(
                    ClipboardData(text: ExportService.productsCsv(items)));
                if (context.mounted) {
                  showMessage(
                      context, 'CSV copied. Paste into Excel / Google Sheets.');
                }
              },
            ),
          ],
        );
      },
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
