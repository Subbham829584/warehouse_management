import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:warehouse_management/core/app_scope.dart';
import 'package:warehouse_management/core/formatters.dart';
import 'package:warehouse_management/core/ui.dart';
import 'package:warehouse_management/models/product.dart';
import 'package:warehouse_management/models/stock_movement.dart';
import 'package:warehouse_management/screens/product_form_page.dart';
import 'package:warehouse_management/utils/color_palette.dart';
import 'package:warehouse_management/widgets/empty_state.dart';
import 'package:warehouse_management/widgets/stock_badge.dart';

class MovementTile extends StatelessWidget {
  const MovementTile(this.movement, {super.key});
  final StockMovement movement;

  @override
  Widget build(BuildContext context) {
    final isPositive = movement.change > 0;
    final isNegative = movement.change < 0;
    final color = isPositive
        ? const Color(0xff2e9e6b)
        : isNegative
            ? const Color(0xffe75757)
            : const Color(0xffe8a317);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.15),
        child: Icon(
          isPositive
              ? Icons.arrow_downward
              : isNegative
                  ? Icons.arrow_upward
                  : Icons.sync,
          color: color,
        ),
      ),
      title: Text(
        movement.productName.isEmpty ? 'Product' : movement.productName,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${movement.type.label} • ${Fmt.dateTime(movement.createdAt)}',
            style: const TextStyle(fontSize: 12),
          ),
          if (movement.note.isNotEmpty)
            Text(
              movement.note,
              style: TextStyle(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: Colors.grey.shade700,
              ),
            ),
          if (movement.userEmail.isNotEmpty)
            Text(
              'By: ${movement.userEmail}',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${isPositive ? '+' : ''}${movement.change}',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            'Qty: ${movement.quantityAfter}',
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class ProductDetailsPage extends StatelessWidget {
  final ProductItem? item;
  final Product? product;
  final String? docID;

  const ProductDetailsPage({
    super.key,
    this.item,
    this.product,
    this.docID,
  });

  String get _id => item?.id ?? docID ?? '';

  Future<void> _adjustStock(
    BuildContext context, {
    required MovementType type,
    required Product currentProduct,
  }) async {
    final qtyCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    final title = switch (type) {
      MovementType.stockIn => 'Stock In (Receive)',
      MovementType.stockOut => 'Stock Out (Dispatch)',
      MovementType.adjustment => 'Stock Count / Audit',
    };
    final label = switch (type) {
      MovementType.stockIn => 'Quantity to add',
      MovementType.stockOut => 'Quantity to remove',
      MovementType.adjustment => 'Actual count on shelf',
    };

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: qtyCtrl,
              autofocus: true,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: label,
                helperText: type == MovementType.stockOut
                    ? 'Available: ${currentProduct.quantity}'
                    : null,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteCtrl,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                hintText: 'e.g. PO-102 or Invoice #',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    final qty = int.tryParse(qtyCtrl.text.trim());
    if (qty == null || qty < 0 || (qty == 0 && type != MovementType.adjustment)) {
      if (context.mounted) showMessage(context, 'Enter a valid quantity', error: true);
      return;
    }

    final scope = AppScope.of(context);
    try {
      await scope.repo.adjustStock(
        productId: _id,
        type: type,
        amount: qty,
        userEmail: scope.userEmail,
        note: noteCtrl.text.trim(),
      );
      if (context.mounted) {
        showMessage(context, 'Stock updated successfully');
      }
    } catch (e) {
      if (context.mounted) {
        showMessage(context, '$e'.replaceFirst('Bad state: ', ''), error: true);
      }
    }
  }

  Future<void> _delete(BuildContext context, Product p) async {
    final ok = await confirm(
      context,
      title: 'Delete product?',
      message: 'Are you sure you want to delete "${p.name}"? This cannot be undone.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!ok) return;

    final repo = AppScope.of(context).repo;
    try {
      await repo.deleteProduct(_id);
      if (context.mounted) {
        showMessage(context, 'Product deleted');
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (context.mounted) showMessage(context, 'Failed: $e', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = AppScope.of(context).repo;
    final initialProduct = item?.product ?? product ?? const Product();

    return StreamBuilder<List<ProductItem>>(
      stream: repo.watchProducts(),
      builder: (context, snap) {
        final currentItem = snap.data?.firstWhere(
              (p) => p.id == _id,
              orElse: () => ProductItem(id: _id, product: initialProduct),
            ) ??
            ProductItem(id: _id, product: initialProduct);
        final p = currentItem.product;

        return Scaffold(
          appBar: AppBar(
            title: Text(p.name.isEmpty ? 'Product Details' : p.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Edit details',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ProductFormPage(item: currentItem),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Delete product',
                onPressed: () => _delete(context, p),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Product Hero Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          height: 100,
                          width: 100,
                          color: ColorPalette.geyser.withValues(alpha: 0.3),
                          child: (p.image.trim().isNotEmpty)
                              ? CachedNetworkImage(
                                  imageUrl: p.image.trim(),
                                  fit: BoxFit.cover,
                                  errorWidget: (_, __, ___) => const Icon(
                                    Icons.inventory_2_outlined,
                                    size: 40,
                                    color: ColorPalette.timberGreen,
                                  ),
                                )
                              : const Icon(
                                  Icons.inventory_2_outlined,
                                  size: 40,
                                  color: ColorPalette.timberGreen,
                                ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.name.isEmpty ? 'Unnamed' : p.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: ColorPalette.timberGreen,
                              ),
                            ),
                            const SizedBox(height: 4),
                            StockBadge(p),
                            const SizedBox(height: 8),
                            Text(
                              '${p.quantity} ${p.unit} in stock',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: ColorPalette.nileBlue,
                              ),
                            ),
                            Text(
                              'Value: ${Fmt.money(p.totalValue)}',
                              style: TextStyle(
                                fontSize: 13,
                                color: ColorPalette.timberGreen.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Quick Stock Actions
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Stock Operations',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: ColorPalette.timberGreen,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xff2e9e6b),
                              ),
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Stock In'),
                              onPressed: () => _adjustStock(
                                context,
                                type: MovementType.stockIn,
                                currentProduct: p,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xffe75757),
                              ),
                              icon: const Icon(Icons.remove, size: 18),
                              label: const Text('Stock Out'),
                              onPressed: () => _adjustStock(
                                context,
                                type: MovementType.stockOut,
                                currentProduct: p,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.pin, size: 18),
                              label: const Text('Count'),
                              onPressed: () => _adjustStock(
                                context,
                                type: MovementType.adjustment,
                                currentProduct: p,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Metadata card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Product Information',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: ColorPalette.timberGreen,
                        ),
                      ),
                      const Divider(height: 24),
                      _infoRow('Group', p.group.isEmpty ? '-' : p.group),
                      _infoRow('Company / Brand', p.company.isEmpty ? '-' : p.company),
                      _infoRow('Storage Location', p.location.isEmpty ? '-' : p.location),
                      _infoRow('SKU', p.sku.isEmpty ? '-' : p.sku),
                      _infoRow('Barcode', p.barcode.isEmpty ? '-' : p.barcode),
                      _infoRow('Unit Cost', Fmt.money(p.cost)),
                      _infoRow('Min Stock Alert Level', '${p.minStock} ${p.unit}'),
                      if (p.description.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        const Text(
                          'Description',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          p.description,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Activity / Audit Trail
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Audit Trail',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: ColorPalette.timberGreen,
                        ),
                      ),
                      const SizedBox(height: 8),
                      StreamBuilder<List<StockMovement>>(
                        stream: repo.watchMovements(productId: _id),
                        builder: (context, mSnap) {
                          if (mSnap.hasError) return ErrorState(mSnap.error);
                          if (!mSnap.hasData) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }
                          final list = mSnap.data!;
                          if (list.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(child: Text('No movements recorded yet.')),
                            );
                          }
                          return ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: list.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (_, i) => MovementTile(list[i]),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: ColorPalette.timberGreen.withValues(alpha: 0.7),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: ColorPalette.timberGreen,
            ),
          ),
        ],
      ),
    );
  }
}
