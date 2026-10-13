/// App-wide constants. Keep magic strings here, not scattered in screens.
class AppConstants {
  AppConstants._();

  static const String appName = 'Warehouse Management';
  static const String currency = '\u20B9';

  /// Default stock level at/below which a product is flagged "low stock".
  static const int defaultLowStockThreshold = 10;

  /// Selectable storage locations (replace with a Firestore collection later).
  static const List<String> locations = [
    'Godown 1, 1st Floor',
    'Godown 1, 2nd Floor',
    'Godown 2, 1st Floor',
    'Godown 2, 2nd Floor',
  ];

  static const List<String> units = [
    'pcs',
    'box',
    'kg',
    'litre',
    'pack',
    'roll'
  ];

  // Firestore collection names
  static const String warehousesCol = 'warehouse';
  static const String productsCol = 'products';
  static const String groupsCol = 'product_groups';
  static const String movementsCol = 'stock_movements';
  static const String usersCol = 'users';
}
