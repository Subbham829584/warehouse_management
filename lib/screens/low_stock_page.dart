import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:warehouse_management/core/app_scope.dart';
import 'package:warehouse_management/core/ui.dart';
import 'package:warehouse_management/models/inventory_stats.dart';
import 'package:warehouse_management/models/product.dart';
import 'package:warehouse_management/services/export_service.dart';
import 'package:warehouse_management/widgets/empty_state.dart';
import 'package:warehouse_management/widgets/product_card.dart';

class LowStockPage extends StatelessWidget {
  const LowStockPage({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = AppScope.of(context).repo;
    return Scaffold(
      appBar: AppBar(title: const Text('Needs restocking')),
      body: StreamBuilder<List<ProductItem>>(
        stream: repo.watchProducts(),
        builder: (context, snap) {
          if (snap.hasError) return ErrorState(snap.error);
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final s = InventoryStats.from(snap.data!);
          final list = [...s.outOfStock, ...s.lowStock];
          if (list.isEmpty) {
            return const EmptyState(
              icon: Icons.check_circle_outline,
              title: 'Everything is well stocked 🎉',
            );
          }
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  itemBuilder: (_, i) => ProductCard(item: list[i]),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.copy),
                    label: const Text('Copy reorder list (CSV)'),
                    onPressed: () async {
                      await Clipboard.setData(
                        ClipboardData(text: ExportService.productsCsv(list)),
                      );
                      if (context.mounted) {
                        showMessage(context, 'Reorder list copied');
                      }
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
