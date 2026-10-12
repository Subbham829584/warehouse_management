import 'package:warehouse_management/models/product.dart';
import 'package:warehouse_management/models/stock_movement.dart';

/// Single contract for all inventory data. Screens depend on this,
/// never on Firestore directly, so demo mode and tests are trivial.
abstract class InventoryRepository {
  // Groups
  Stream<List<String>> watchGroups();
  Future<bool> addGroup(String name);
  Future<void> deleteGroup(String name);

  // Products
  Stream<List<ProductItem>> watchProducts({String? group});
  Future<String> addProduct(Product product, {required String userEmail});
  Future<void> updateProduct(String id, Product product);
  Future<void> deleteProduct(String id);

  /// Client-side filter over the live stream (name, company, SKU, barcode).
  Stream<List<ProductItem>> searchProducts(String query, {String? group});

  /// Find a product by barcode or SKU (used by the scanner).
  Future<ProductItem?> findByCode(String code);

  // Stock movements
  Future<void> adjustStock({
    required String productId,
    required MovementType type,
    required int amount,
    required String userEmail,
    String note = '',
  });
  Stream<List<StockMovement>> watchMovements(
      {String? productId, int limit = 100});
}

class InsufficientStockException implements Exception {
  InsufficientStockException(this.available, this.requested);
  final int available;
  final int requested;
  @override
  String toString() => 'Only $available in stock, cannot remove $requested.';
}

/// Shared filter used by both implementations (and covered by unit tests).
bool productMatches(Product p, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return true;
  return p.name.toLowerCase().contains(q) ||
      p.company.toLowerCase().contains(q) ||
      p.sku.toLowerCase().contains(q) ||
      p.barcode.toLowerCase().contains(q);
}
