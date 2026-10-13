import 'package:warehouse_management/models/product.dart';

/// Pure computation over a product list — easy to unit test.
class InventoryStats {
  InventoryStats._(this.totalProducts, this.totalUnits, this.totalValue,
      this.lowStock, this.outOfStock, this.valueByGroup, this.unitsByLocation,);

  final int totalProducts;
  final int totalUnits;
  final double totalValue;
  final List<ProductItem> lowStock;
  final List<ProductItem> outOfStock;
  final Map<String, double> valueByGroup;
  final Map<String, int> unitsByLocation;

  factory InventoryStats.from(List<ProductItem> items) {
    var units = 0;
    var value = 0.0;
    final low = <ProductItem>[];
    final out = <ProductItem>[];
    final byGroup = <String, double>{};
    final byLoc = <String, int>{};

    for (final i in items) {
      final p = i.product;
      units += p.quantity;
      value += p.totalValue;
      byGroup.update(
          p.group.isEmpty ? 'Ungrouped' : p.group, (v) => v + p.totalValue,
          ifAbsent: () => p.totalValue,);
      byLoc.update(
          p.location.isEmpty ? 'Unassigned' : p.location, (v) => v + p.quantity,
          ifAbsent: () => p.quantity,);
      if (p.isOutOfStock) {
        out.add(i);
      } else if (p.isLowStock) {
        low.add(i);
      }
    }
    return InventoryStats._(
        items.length, units, value, low, out, byGroup, byLoc,);
  }
}
