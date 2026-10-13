import 'package:warehouse_management/models/product.dart';
import 'package:warehouse_management/models/stock_movement.dart';

/// Builds RFC-4180 CSV strings. Pure functions => unit-testable.
class ExportService {
  ExportService._();

  static String _cell(Object? v) {
    var s = '${v ?? ''}';
    // Neutralise spreadsheet formula injection (=, +, -, @ at start).
    if (s.isNotEmpty && '=+-@'.contains(s[0]) && double.tryParse(s) == null) {
      s = "'$s";
    }
    if (s.contains(',') || s.contains('"') || s.contains('\n')) {
      s = '"${s.replaceAll('"', '""')}"';
    }
    return s;
  }

  static String _row(List<Object?> cells) => cells.map(_cell).join(',');

  static String productsCsv(List<ProductItem> items) {
    final b = StringBuffer()
      ..writeln(_row([
        'Name',
        'SKU',
        'Barcode',
        'Group',
        'Company',
        'Location',
        'Quantity',
        'Unit',
        'Min Stock',
        'Unit Cost',
        'Total Value',
        'Status',
      ]),);
    for (final i in items) {
      final p = i.product;
      final status = p.isOutOfStock
          ? 'Out of stock'
          : p.isLowStock
              ? 'Low stock'
              : 'In stock';
      b.writeln(_row([
        p.name,
        p.sku,
        p.barcode,
        p.group,
        p.company,
        p.location,
        p.quantity,
        p.unit,
        p.minStock,
        p.cost.toStringAsFixed(2),
        p.totalValue.toStringAsFixed(2),
        status,
      ]),);
    }
    return b.toString();
  }

  static String movementsCsv(List<StockMovement> list) {
    final b = StringBuffer()
      ..writeln(_row([
        'Date',
        'Product',
        'Type',
        'Change',
        'Quantity After',
        'User',
        'Note',
      ]),);
    for (final m in list) {
      b.writeln(_row([
        m.createdAt?.toIso8601String() ?? '',
        m.productName,
        m.type.label,
        m.change,
        m.quantityAfter,
        m.userEmail,
        m.note,
      ]),);
    }
    return b.toString();
  }
}
