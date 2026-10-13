import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:warehouse_management/core/constants.dart';
import 'package:warehouse_management/models/product.dart';
import 'package:warehouse_management/models/stock_movement.dart';
import 'package:warehouse_management/repositories/inventory_repository.dart';

/// All data lives under /warehouse/{warehouseId}/...
class FirestoreInventoryRepository implements InventoryRepository {
  FirestoreInventoryRepository({
    required this.warehouseId,
    FirebaseFirestore? firestore,
  }) : _db = firestore ?? FirebaseFirestore.instance;

  final String warehouseId;
  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> get _root =>
      _db.collection(AppConstants.warehousesCol).doc(warehouseId);
  CollectionReference<Map<String, dynamic>> get _products =>
      _root.collection(AppConstants.productsCol);
  CollectionReference<Map<String, dynamic>> get _groups =>
      _root.collection(AppConstants.groupsCol);
  CollectionReference<Map<String, dynamic>> get _movements =>
      _root.collection(AppConstants.movementsCol);

  // ---------------- Groups ----------------
  @override
  Stream<List<String>> watchGroups() => _groups.snapshots().map((s) {
        final list = s.docs
            .map((d) => (d.data()['name'] as String?)?.trim() ?? '')
            .where((n) => n.isNotEmpty)
            .toList()
          ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
        return list;
      });

  @override
  Future<bool> addGroup(String name) async {
    final n = name.trim();
    if (n.isEmpty) return false;
    // Doc id = lower-cased name, so duplicates are impossible (no race).
    final ref = _groups.doc(n.toLowerCase().replaceAll('/', '-'));
    final exists = (await ref.get()).exists;
    if (exists) return false;
    await ref.set({'name': n, 'createdAt': FieldValue.serverTimestamp()});
    return true;
  }

  @override
  Future<void> deleteGroup(String name) async {
    // Refuse to orphan products.
    final inUse =
        await _products.where('group', isEqualTo: name).limit(1).get();
    if (inUse.docs.isNotEmpty) {
      throw StateError(
          'Group "$name" still has products. Move or delete them first.',);
    }
    final q = await _groups.where('name', isEqualTo: name).get();
    final batch = _db.batch();
    for (final d in q.docs) {
      batch.delete(d.reference);
    }
    await batch.commit();
  }

  // ---------------- Products ----------------
  @override
  Stream<List<ProductItem>> watchProducts({String? group}) {
    Query<Map<String, dynamic>> q = _products;
    if (group != null && group.isNotEmpty) {
      q = q.where('group', isEqualTo: group);
    }
    // Sorted client-side: avoids needing a composite index.
    return q.snapshots().map((s) {
      final list = s.docs
          .map((d) => ProductItem(id: d.id, product: Product.fromMap(d.data())))
          .toList()
        ..sort((a, b) => a.product.name
            .toLowerCase()
            .compareTo(b.product.name.toLowerCase()),);
      return list;
    });
  }

  @override
  Future<String> addProduct(Product product,
      {required String userEmail,}) async {
    final ref = _products.doc();
    final batch = _db.batch();
    batch.set(ref, {
      ...product.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    if (product.quantity > 0) {
      batch.set(
          _movements.doc(),
          StockMovement(
            id: '',
            productId: ref.id,
            productName: product.name,
            type: MovementType.stockIn,
            change: product.quantity,
            quantityAfter: product.quantity,
            userEmail: userEmail,
            note: 'Opening stock',
          ).toMap(),);
    }
    await batch.commit();
    return ref.id;
  }

  /// Edits metadata. Quantity changes should go through [adjustStock]
  /// so they are audited; here quantity is deliberately NOT overwritten.
  @override
  Future<void> updateProduct(String id, Product product) async {
    final data = product.toMap()..remove('quantity');
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _products.doc(id).update(data);
  }

  @override
  Future<void> deleteProduct(String id) => _products.doc(id).delete();

  @override
  Stream<List<ProductItem>> searchProducts(String query, {String? group}) =>
      watchProducts(group: group).map((items) =>
          items.where((i) => productMatches(i.product, query)).toList(),);

  @override
  Future<ProductItem?> findByCode(String code) async {
    final c = code.trim();
    if (c.isEmpty) return null;
    for (final field in ['barcode', 'sku']) {
      final q = await _products.where(field, isEqualTo: c).limit(1).get();
      if (q.docs.isNotEmpty) {
        final d = q.docs.first;
        return ProductItem(id: d.id, product: Product.fromMap(d.data()));
      }
    }
    return null;
  }

  // ---------------- Stock movements ----------------
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
    final ref = _products.doc(productId);

    // Transaction => two people scanning at once can't corrupt the count.
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) throw StateError('Product no longer exists.');
      final p = Product.fromMap(snap.data()!);

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
          // For adjustments, `amount` is the new counted quantity.
          if (amount < 0) throw ArgumentError('Count cannot be negative.');
          newQty = amount;
          delta = amount - p.quantity;
      }

      tx.update(ref, {
        'quantity': newQty,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      tx.set(
        _movements.doc(),
        StockMovement(
          id: '',
          productId: productId,
          productName: p.name,
          type: type,
          change: delta,
          quantityAfter: newQty,
          userEmail: userEmail,
          note: note,
        ).toMap(),
      );
    });
  }

  @override
  Stream<List<StockMovement>> watchMovements(
      {String? productId, int limit = 100,}) {
    Query<Map<String, dynamic>> q = _movements;
    if (productId != null) q = q.where('productId', isEqualTo: productId);
    return q
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => StockMovement.fromMap(d.id, d.data())).toList(),);
  }
}
