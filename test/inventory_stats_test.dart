import 'package:flutter_test/flutter_test.dart';
import 'package:warehouse_management/models/inventory_stats.dart';
import 'package:warehouse_management/models/product.dart';

ProductItem item(String id,
        {int q = 10,
        double c = 1,
        int min = 5,
        String g = 'A',
        String loc = 'L1',}) =>
    ProductItem(
        id: id,
        product: Product(
            name: id,
            quantity: q,
            cost: c,
            minStock: min,
            group: g,
            location: loc,),);

void main() {
  test('empty list', () {
    final s = InventoryStats.from([]);
    expect(s.totalProducts, 0);
    expect(s.totalValue, 0);
  });

  test('totals, low and out of stock', () {
    final s = InventoryStats.from([
      item('ok', q: 100, c: 2),
      item('low', q: 3, c: 10),
      item('out', q: 0, c: 50),
    ]);
    expect(s.totalProducts, 3);
    expect(s.totalUnits, 103);
    expect(s.totalValue, 230);
    expect(s.lowStock.map((i) => i.id), ['low']);
    expect(s.outOfStock.map((i) => i.id), ['out']);
  });

  test('aggregates by group and location', () {
    final s = InventoryStats.from([
      item('a', q: 2, c: 10, g: 'X'),
      item('b', q: 3, c: 10, g: 'X', loc: 'L2'),
      item('c', q: 1, c: 5, g: '', loc: ''),
    ]);
    expect(s.valueByGroup['X'], 50);
    expect(s.valueByGroup['Ungrouped'], 5);
    expect(s.unitsByLocation['L1'], 2);
    expect(s.unitsByLocation['Unassigned'], 1);
  });
}
