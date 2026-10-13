import 'dart:async';
import 'package:warehouse_management/models/product.dart';
import 'package:warehouse_management/models/stock_movement.dart';
import 'package:warehouse_management/repositories/inventory_repository.dart';

/// In-memory implementation for demo mode and unit tests.
class MemoryInventoryRepository implements InventoryRepository {
  MemoryInventoryRepository({bool seed = true}) {
    if (seed) _seed();
  }

  final List<String> _groups = [];
  final List<ProductItem> _products = [];
  final List<StockMovement> _movements = [];
  int _idCounter = 0;

  final _groupsCtrl = StreamController<List<String>>.broadcast();
  final _productsCtrl = StreamController<List<ProductItem>>.broadcast();
  final _movementsCtrl = StreamController<List<StockMovement>>.broadcast();

  String _nextId(String prefix) => '${prefix}_${++_idCounter}';

  void _emitGroups() => _groupsCtrl.add(_sortedGroups());
  void _emitProducts() => _productsCtrl.add(List.of(_products));
  void _emitMovements() => _movementsCtrl.add(List.of(_movements));

  List<String> _sortedGroups() => List.of(_groups)
    ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

  /// Emits current value first, then live updates (mimics Firestore).
  Stream<T> _live<T>(T Function() current, Stream<T> updates) async* {
    yield current();
    yield* updates;
  }

  // ---------------- Groups ----------------
  @override
  Stream<List<String>> watchGroups() =>
      _live(_sortedGroups, _groupsCtrl.stream);

  @override
  Future<bool> addGroup(String name) async {
    final n = name.trim();
    if (n.isEmpty || _groups.any((g) => g.toLowerCase() == n.toLowerCase())) {
      return false;
    }
    _groups.add(n);
    _emitGroups();
    return true;
  }

  @override
  Future<void> deleteGroup(String name) async {
    if (_products.any((p) => p.product.group == name)) {
      throw StateError(
          'Group "$name" still has products. Move or delete them first.',);
    }
    _groups.remove(name);
    _emitGroups();
  }

  // ---------------- Products ----------------
  List<ProductItem> _filtered(String? group) {
    final list = _products
        .where(
            (i) => group == null || group.isEmpty || i.product.group == group,)
        .toList()
      ..sort((a, b) =>
          a.product.name.toLowerCase().compareTo(b.product.name.toLowerCase()),);
    return list;
  }

  @override
  Stream<List<ProductItem>> watchProducts({String? group}) => _live(
      () => _filtered(group),
      _productsCtrl.stream.map((_) => _filtered(group)),);

  @override
  Future<String> addProduct(Product product,
      {required String userEmail,}) async {
    final id = _nextId('prod');
    _products.add(ProductItem(id: id, product: product));
    if (product.quantity > 0) {
      _log(id, product.name, MovementType.stockIn, product.quantity,
          product.quantity, userEmail, 'Opening stock',);
    }
    _emitProducts();
    return id;
  }

  @override
  Future<void> updateProduct(String id, Product product) async {
    final i = _products.indexWhere((p) => p.id == id);
    if (i == -1) return;
    // Preserve quantity: it changes only through adjustStock.
    _products[i] = ProductItem(
        id: id,
        product: product.copyWith(quantity: _products[i].product.quantity),);
    _emitProducts();
  }

  @override
  Future<void> deleteProduct(String id) async {
    _products.removeWhere((p) => p.id == id);
    _emitProducts();
  }

  @override
  Stream<List<ProductItem>> searchProducts(String query, {String? group}) =>
      watchProducts(group: group).map((items) =>
          items.where((i) => productMatches(i.product, query)).toList(),);

  @override
  Future<ProductItem?> findByCode(String code) async {
    final c = code.trim();
    if (c.isEmpty) return null;
    for (final i in _products) {
      if (i.product.barcode == c || i.product.sku == c) return i;
    }
    return null;
  }

  // ---------------- Movements ----------------
  void _log(String pid, String name, MovementType t, int change, int after,
      String user, String note,) {
    _movements.insert(
      0,
      StockMovement(
        id: _nextId('mv'),
        productId: pid,
        productName: name,
        type: t,
        change: change,
        quantityAfter: after,
        userEmail: user,
        note: note,
        createdAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<void> adjustStock({
    required String productId,
    required MovementType type,
    required int amount,
    required String userEmail,
    String note = '',
  }) async {
    if (amount <= 0 && type != MovementType.adjustment) {
      throw ArgumentError('Amount must be greater than zero.');
    }
    final i = _products.indexWhere((p) => p.id == productId);
    if (i == -1) throw StateError('Product no longer exists.');
    final p = _products[i].product;

    final int newQty;
    final int delta;
    switch (type) {
      case MovementType.stockIn:
        delta = amount;
        newQty = p.quantity + amount;
      case MovementType.stockOut:
        if (amount > p.quantity) {
          throw InsufficientStockException(p.quantity, amount);
        }
        delta = -amount;
        newQty = p.quantity - amount;
      case MovementType.adjustment:
        if (amount < 0) throw ArgumentError('Count cannot be negative.');
        newQty = amount;
        delta = amount - p.quantity;
    }
    _products[i] =
        ProductItem(id: productId, product: p.copyWith(quantity: newQty));
    _log(productId, p.name, type, delta, newQty, userEmail, note);
    _emitProducts();
    _emitMovements();
  }

  @override
  Stream<List<StockMovement>> watchMovements(
      {String? productId, int limit = 100,}) {
    List<StockMovement> current() => _movements
        .where((m) => productId == null || m.productId == productId)
        .take(limit)
        .toList();
    return _live(current, _movementsCtrl.stream.map((_) => current()));
  }

  // ---------------- Demo data ----------------
  void _seed() {
    _groups.addAll([
      'Electronics',
      'Industrial Tools',
      'Packaging Materials',
      'Hardware & Fasteners',
      'Safety & PPE',
    ]);
    Product p(String n, double c, String g, String loc, String co, int q,
            String sku, {int min = 10, String unit = 'pcs',}) =>
        Product(
            name: n,
            cost: c,
            group: g,
            location: loc,
            company: co,
            quantity: q,
            sku: sku,
            barcode: '890$sku',
            minStock: min,
            unit: unit,);
    final demo = [
      p('Wireless Barcode Scanner 2D', 4500, 'Electronics',
          'Godown 1, 1st Floor', 'Zebra Tech', 38, '1001',),
      p('Thermal Shipping Label Printer', 12500, 'Electronics',
          'Godown 1, 2nd Floor', 'TSC Auto ID', 4, '1002',
          min: 5,),
      p('Hydraulic Pallet Truck 2.5T', 18500, 'Industrial Tools',
          'Godown 1, 1st Floor', 'Godrej', 9, '1003',
          min: 3,),
      p('Digital Platform Weighing Scale', 8200, 'Industrial Tools',
          'Godown 2, 2nd Floor', 'Essae Weighing', 0, '1004',
          min: 5,),
      p('Pallet Stretch Film Rolls (500mm)', 650, 'Packaging Materials',
          'Godown 2, 1st Floor', 'PolyPack Ltd', 140, '1005',
          unit: 'roll', min: 30,),
      p('5-Ply Carton Box (Pack 25)', 1750, 'Packaging Materials',
          'Godown 1, 2nd Floor', 'BoxCraft', 12, '1006',
          unit: 'pack', min: 20,),
      p('Safety Helmet (Yellow)', 420, 'Safety & PPE', 'Godown 1, 1st Floor',
          'Karam Safety', 65, '1007',
          min: 15,),
      p('SS Hex Bolts M10x50', 25, 'Hardware & Fasteners',
          'Godown 2, 2nd Floor', 'Unbrako', 450, '1008',
          min: 100,),
    ];
    for (final d in demo) {
      final id = _nextId('prod');
      _products.add(ProductItem(id: id, product: d));
      _log(id, d.name, MovementType.stockIn, d.quantity, d.quantity, 'system',
          'Opening stock',);
    }
  }
}
