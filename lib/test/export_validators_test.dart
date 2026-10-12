import 'package:flutter_test/flutter_test.dart';
import 'package:warehouse_management/core/validators.dart';
import 'package:warehouse_management/models/product.dart';
import 'package:warehouse_management/services/export_service.dart';

void main() {
  group('CSV export', () {
    test('header + one row, quoting commas and quotes', () {
      final csv = ExportService.productsCsv([
        const ProductItem(
          id: '1',
          product:
              Product(name: 'Bolt, "M10"', cost: 2.5, quantity: 4, group: 'H'),
        ),
      ]);
      final lines = csv.trim().split('\n');
      expect(lines, hasLength(2));
      expect(lines[1], contains('"Bolt, ""M10"""'));
      expect(lines[1], contains('10.00')); // total value
    });

    test('formula injection is neutralised', () {
      final csv = ExportService.productsCsv([
        const ProductItem(id: '1', product: Product(name: '=HYPERLINK("x")')),
      ]);
      expect(
          csv.split('\n')[1].startsWith("\"'=HYPERLINK") ||
              csv.split('\n')[1].startsWith("'="),
          isTrue);
    });
  });

  group('Validators', () {
    test('email', () {
      expect(Validators.email('a@b.co'), isNull);
      expect(Validators.email('a@b'), isNotNull);
      expect(Validators.email(''), isNotNull);
    });
    test('password needs 8+ chars', () {
      expect(Validators.password('1234567'), isNotNull);
      expect(Validators.password('12345678'), isNull);
    });
    test('numbers', () {
      expect(Validators.nonNegativeInt('5'), isNull);
      expect(Validators.nonNegativeInt('-1'), isNotNull);
      expect(Validators.nonNegativeInt('2.5'), isNotNull);
      expect(Validators.nonNegativeNumber('2.5'), isNull);
      expect(Validators.nonNegativeNumber('abc'), isNotNull);
    });
  });
}
