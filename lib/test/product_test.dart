import 'package:flutter_test/flutter_test.dart';
import 'package:warehouse_management/models/product.dart';

void main() {
  group('Product', () {
    test('stock status flags', () {
      expect(const Product(quantity: 0).isOutOfStock, isTrue);
      expect(const Product(quantity: 5, minStock: 10).isLowStock, isTrue);
      expect(const Product(quantity: 10, minStock: 10).isLowStock, isTrue);
      expect(const Product(quantity: 11, minStock: 10).isLowStock, isFalse);
      // Out of stock is NOT also "low stock" (no double counting).
      expect(const Product(quantity: 0, minStock: 10).isLowStock, isFalse);
    });

    test('totalValue = cost * quantity', () {
      expect(const Product(cost: 12.5, quantity: 4).totalValue, 50);
    });

    test('fromMap is backward compatible with the old schema', () {
      final p = Product.fromMap({
        'name': 'Bolt',
        'cost': 25, // int, not double
        'quantity': 450,
        'group': 'Hardware',
      });
      expect(p.cost, 25.0);
      expect(p.unit, 'pcs');
      expect(p.sku, '');
      expect(p.minStock, 10);
    });

    test('fromMap tolerates nulls', () {
      final p = Product.fromMap({});
      expect(p.name, '');
      expect(p.quantity, 0);
    });

    test('toMap trims and lowercases helper field', () {
      final m = const Product(name: '  Helmet ').toMap();
      expect(m['name'], 'Helmet');
      expect(m['nameLower'], 'helmet');
    });
  });
}
