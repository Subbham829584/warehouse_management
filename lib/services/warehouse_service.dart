import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:warehouse_management/firebase_options.dart';
import 'package:warehouse_management/models/product.dart';

class WarehouseProductItem {
  final String id;
  final Product product;

  WarehouseProductItem({required this.id, required this.product});
}

class WarehouseService {
  WarehouseService._() {
    _initMockData();
  }
  static final WarehouseService instance = WarehouseService._();

  bool _initialized = false;
  bool _mockIsLoggedIn = false;
  String _mockUserEmail = 'demo.manager@warehouse.io';

  /// Default warehouse document ID from your Firebase collection (/warehouse/Aa3SUKLQScIhcYYkBB1K)
  String _currentWarehouseId = 'Aa3SUKLQScIhcYYkBB1K';
  String get currentWarehouseId => _currentWarehouseId;

  set currentWarehouseId(String id) {
    if (id.trim().isNotEmpty && _currentWarehouseId != id.trim()) {
      _currentWarehouseId = id.trim();
      _notifyAllStreams();
    }
  }

  final StreamController<bool> _authStateController =
      StreamController<bool>.broadcast();
  final StreamController<List<String>> _groupsController =
      StreamController<List<String>>.broadcast();
  final StreamController<List<WarehouseProductItem>> _productsController =
      StreamController<List<WarehouseProductItem>>.broadcast();

  List<String> _mockGroups = [];
  final List<WarehouseProductItem> _mockProducts = [];

  bool get isFirebaseActive => DefaultFirebaseOptions.isConfigured;
  bool get isFrontendMode => !DefaultFirebaseOptions.isConfigured;

  // ===================== FIRESTORE PATH HELPERS =====================
  // Root collection: /warehouse
  // Document: /warehouse/{currentWarehouseId}
  // Subcollections:
  //   - /warehouse/{currentWarehouseId}/product_groups
  //   - /warehouse/{currentWarehouseId}/products

  CollectionReference<Map<String, dynamic>> get _warehouseRootCollection =>
      FirebaseFirestore.instance.collection("warehouse");

  DocumentReference<Map<String, dynamic>> get _warehouseDocRef =>
      _warehouseRootCollection.doc(_currentWarehouseId);

  CollectionReference<Map<String, dynamic>> get _productsCollection =>
      _warehouseDocRef.collection("products");

  CollectionReference<Map<String, dynamic>> get _productGroupsCollection =>
      _warehouseDocRef.collection("product_groups");

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    if (isFirebaseActive) {
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        // Ensure the warehouse root document and default collections exist
        await _ensureWarehouseDocExists();
      } catch (e) {
        // ignore: avoid_print
        print("Firebase initialization fallback: $e");
      }
    }
  }

  Future<void> _ensureWarehouseDocExists() async {
    try {
      final doc = await _warehouseDocRef.get();
      if (!doc.exists) {
        await _warehouseDocRef.set({
          'id': _currentWarehouseId,
          'name': 'Warehouse Management Godown',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      // Automatically seed default product groups into Firestore if collection is empty
      final groupsSnapshot = await _productGroupsCollection.limit(1).get();
      if (groupsSnapshot.docs.isEmpty) {
        final batch = FirebaseFirestore.instance.batch();
        for (final groupName in _mockGroups) {
          final docRef = _productGroupsCollection.doc();
          batch.set(docRef, {
            'name': groupName,
            'warehouseId': _currentWarehouseId,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
        await batch.commit();
      }

      // Automatically seed sample products into Firestore if collection is empty
      final productsSnapshot = await _productsCollection.limit(1).get();
      if (productsSnapshot.docs.isEmpty) {
        final batch = FirebaseFirestore.instance.batch();
        for (final item in _mockProducts) {
          final docRef = _productsCollection.doc();
          final data = item.product.toMap();
          data['warehouseId'] = _currentWarehouseId;
          data['createdAt'] = FieldValue.serverTimestamp();
          batch.set(docRef, data);
        }
        await batch.commit();
      }
    } catch (e) {
      // ignore: avoid_print
      print("Firestore seed notice: $e");
    }
  }

  void _notifyAllStreams() {
    _groupsController.add(List<String>.from(_mockGroups));
    _productsController.add(List<WarehouseProductItem>.from(_mockProducts));
  }

  void _initMockData() {
    _mockGroups = [
      'Electronics',
      'Industrial Tools',
      'Packaging Materials',
      'Hardware & Fasteners',
      'Safety & PPE',
    ];

    final sampleProducts = [
      WarehouseProductItem(
        id: 'mock_1',
        product: Product(
          name: 'Wireless Barcode Scanner 2D',
          cost: 4500.0,
          group: 'Electronics',
          location: 'Godown 1, 1st Floor',
          company: 'Zebra Tech',
          quantity: 38,
          image:
              'https://images.unsplash.com/photo-1586528116311-ad8dd3c8310d?w=400',
          description:
              'Rugged handheld Bluetooth 2D barcode reader for fast warehouse inventory scanning and item tracking.',
        ),
      ),
      WarehouseProductItem(
        id: 'mock_2',
        product: Product(
          name: 'Thermal Shipping Label Printer',
          cost: 12500.0,
          group: 'Electronics',
          location: 'Godown 1, 2nd Floor',
          company: 'TSC Auto ID',
          quantity: 14,
          image:
              'https://images.unsplash.com/photo-1612815154858-60aa4c59eaa6?w=400',
          description:
              'High-speed direct thermal barcode and 4x6 shipping label printer with Ethernet & USB support.',
        ),
      ),
      WarehouseProductItem(
        id: 'mock_3',
        product: Product(
          name: 'Hydraulic Pallet Truck 2.5T',
          cost: 18500.0,
          group: 'Industrial Tools',
          location: 'Godown 1, 1st Floor',
          company: 'Godrej',
          quantity: 9,
          image:
              'https://images.unsplash.com/photo-1586528116493-a029325540fa?w=400',
          description:
              'Heavy-duty manual hydraulic hand pallet truck with 2500kg lifting capacity and nylon steer wheels.',
        ),
      ),
      WarehouseProductItem(
        id: 'mock_4',
        product: Product(
          name: 'Digital Platform Weighing Scale',
          cost: 8200.0,
          group: 'Industrial Tools',
          location: 'Godown 2, 2nd Floor',
          company: 'Essae Weighing',
          quantity: 22,
          image:
              'https://images.unsplash.com/photo-1581092160607-ee22621dd758?w=400',
          description:
              '300kg industrial electronic weighing scale with bright green LED display and tare function.',
        ),
      ),
      WarehouseProductItem(
        id: 'mock_5',
        product: Product(
          name: 'Pallet Stretch Film Rolls (500mm)',
          cost: 650.0,
          group: 'Packaging Materials',
          location: 'Godown 2, 1st Floor',
          company: 'PolyPack Ltd',
          quantity: 140,
          image:
              'https://images.unsplash.com/photo-1589939705384-5185137a7f0f?w=400',
          description:
              '23 micron high-tensile stretch film for secure pallet wrapping, moisture barrier and dust prevention.',
        ),
      ),
      WarehouseProductItem(
        id: 'mock_6',
        product: Product(
          name: 'Heavy Duty 5-Ply Carton Box (Pack 25)',
          cost: 1750.0,
          group: 'Packaging Materials',
          location: 'Godown 1, 2nd Floor',
          company: 'BoxCraft Containers',
          quantity: 80,
          image:
              'https://images.unsplash.com/photo-1530587191325-3db32d826c18?w=400',
          description:
              'Corrugated shipping boxes (18x12x12 inches) with 150 GSM fluting for heavy item shipping.',
        ),
      ),
      WarehouseProductItem(
        id: 'mock_7',
        product: Product(
          name: 'High Impact Safety Helmet (Yellow)',
          cost: 420.0,
          group: 'Safety & PPE',
          location: 'Godown 1, 1st Floor',
          company: 'Karam Safety',
          quantity: 65,
          image:
              'https://images.unsplash.com/photo-1504307651254-35680f356dfd?w=400',
          description:
              'IS:2925 certified industrial safety helmet with 4-point adjustable ratchet suspension.',
        ),
      ),
      WarehouseProductItem(
        id: 'mock_8',
        product: Product(
          name: 'Stainless Steel Hex Bolts M10x50',
          cost: 25.0,
          group: 'Hardware & Fasteners',
          location: 'Godown 2, 2nd Floor',
          company: 'Unbrako',
          quantity: 450,
          image:
              'https://images.unsplash.com/photo-1581092335397-9583fe92d232?w=400',
          description:
              'Grade 304 SS hex head bolts with matching nuts and washers for warehouse racking installation.',
        ),
      ),
    ];

    _mockProducts.addAll(sampleProducts);
  }

  // ===================== AUTHENTICATION =====================

  Stream<bool> get authStateChanges {
    if (isFirebaseActive) {
      final controller = StreamController<bool>.broadcast();
      void emitState() {
        final isAuth =
            FirebaseAuth.instance.currentUser != null || _mockIsLoggedIn;
        controller.add(isAuth);
      }

      FirebaseAuth.instance.authStateChanges().listen((_) => emitState());
      _authStateController.stream.listen((_) => emitState());
      scheduleMicrotask(emitState);
      return controller.stream;
    } else {
      return _authStateController.stream;
    }
  }

  bool get isAuthenticated {
    if (isFirebaseActive) {
      return FirebaseAuth.instance.currentUser != null || _mockIsLoggedIn;
    }
    return _mockIsLoggedIn;
  }

  String get currentUserEmail {
    if (isFirebaseActive && FirebaseAuth.instance.currentUser != null) {
      final user = FirebaseAuth.instance.currentUser!;
      if (user.isAnonymous) {
        return 'Demo User (Anonymous)';
      }
      return user.email ?? 'Firebase User';
    }
    return _mockUserEmail;
  }

  Future<void> signIn(String email, String password) async {
    if (isFirebaseActive) {
      try {
        await FirebaseAuth.instance
            .signInWithEmailAndPassword(email: email, password: password);
      } on FirebaseAuthException catch (e) {
        // If user account is not created yet, automatically register!
        if (e.code == 'user-not-found' ||
            e.code == 'invalid-credential' ||
            e.code == 'wrong-password') {
          try {
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
              email: email,
              password: password,
            );
          } catch (_) {
            rethrow;
          }
        } else {
          rethrow;
        }
      }
    } else {
      _mockIsLoggedIn = true;
      _mockUserEmail = email.isNotEmpty ? email : 'demo.manager@warehouse.io';
      _authStateController.add(true);
    }
  }

  Future<void> signInAsDemo() async {
    if (isFirebaseActive) {
      try {
        await FirebaseAuth.instance.signInAnonymously();
      } catch (_) {
        _mockIsLoggedIn = true;
        _authStateController.add(true);
      }
    } else {
      _mockIsLoggedIn = true;
      _authStateController.add(true);
    }
  }

  Future<void> signOut() async {
    if (isFirebaseActive) {
      await FirebaseAuth.instance.signOut();
    }
    _mockIsLoggedIn = false;
    _authStateController.add(false);
  }

  // ===================== PRODUCT GROUPS =====================
  // Stored at: /warehouse/{currentWarehouseId}/product_groups/{groupDocId}
  // Document format: { "name": "Electronics", "warehouseId": "...", "createdAt": ... }

  Stream<List<String>> getProductGroupsStream() {
    if (isFirebaseActive) {
      return _productGroupsCollection.snapshots().map((snapshot) {
        final groups = <String>[];
        for (final doc in snapshot.docs) {
          final name = doc.data()['name'] as String?;
          if (name != null && name.trim().isNotEmpty) {
            groups.add(name.trim());
          }
        }
        groups.sort();
        return groups;
      });
    } else {
      scheduleMicrotask(() {
        _groupsController.add(List<String>.from(_mockGroups));
      });
      return _groupsController.stream;
    }
  }

  Future<bool> addProductGroup(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return false;

    if (isFirebaseActive) {
      // Check if group already exists in /warehouse/{warehouseId}/product_groups
      final existing = await _productGroupsCollection
          .where("name", isEqualTo: trimmed)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        return false;
      }

      // Add as a new document in the product_groups collection
      await _productGroupsCollection.add({
        'name': trimmed,
        'warehouseId': _currentWarehouseId,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return true;
    } else {
      if (_mockGroups.any((g) => g.toLowerCase() == trimmed.toLowerCase())) {
        return false;
      }
      _mockGroups.add(trimmed);
      _groupsController.add(List<String>.from(_mockGroups));
      return true;
    }
  }

  Future<void> deleteProductGroup(String name) async {
    final trimmed = name.trim();
    if (isFirebaseActive) {
      final query = await _productGroupsCollection
          .where("name", isEqualTo: trimmed)
          .get();
      for (final doc in query.docs) {
        await doc.reference.delete();
      }
    } else {
      _mockGroups.removeWhere((g) => g.toLowerCase() == trimmed.toLowerCase());
      _groupsController.add(List<String>.from(_mockGroups));
    }
  }

  // ===================== PRODUCTS =====================
  // Stored at: /warehouse/{currentWarehouseId}/products/{productId}

  Stream<List<WarehouseProductItem>> getProductsStream({String? group}) {
    if (isFirebaseActive) {
      Query<Map<String, dynamic>> query = _productsCollection;
      if (group != null && group.isNotEmpty) {
        query = query.where("group", isEqualTo: group);
      }
      return query.orderBy('name').snapshots().map((snapshot) {
        return snapshot.docs.map((doc) {
          return WarehouseProductItem(
            id: doc.id,
            product: Product.fromMap(doc.data()),
          );
        }).toList();
      });
    } else {
      scheduleMicrotask(() {
        _emitFilteredProducts(group: group);
      });
      return _productsController.stream.map((list) {
        if (group == null || group.isEmpty) return list;
        return list
            .where((item) =>
                item.product.group?.toLowerCase() == group.toLowerCase())
            .toList();
      });
    }
  }

  void _emitFilteredProducts({String? group}) {
    _productsController.add(List<WarehouseProductItem>.from(_mockProducts));
  }

  Future<String> addProduct(Product product) async {
    if (isFirebaseActive) {
      final data = product.toMap();
      data['warehouseId'] = _currentWarehouseId;
      data['createdAt'] = FieldValue.serverTimestamp();
      final ref = await _productsCollection.add(data);
      return ref.id;
    } else {
      final newId = 'prod_${DateTime.now().millisecondsSinceEpoch}';
      final item = WarehouseProductItem(id: newId, product: product);
      _mockProducts.insert(0, item);
      _productsController.add(List<WarehouseProductItem>.from(_mockProducts));
      return newId;
    }
  }

  Future<void> updateProduct(String id, Product product) async {
    if (isFirebaseActive) {
      final data = product.toMap();
      data['updatedAt'] = FieldValue.serverTimestamp();
      await _productsCollection.doc(id).update(data);
    } else {
      final index = _mockProducts.indexWhere((p) => p.id == id);
      if (index != -1) {
        _mockProducts[index] = WarehouseProductItem(id: id, product: product);
        _productsController.add(List<WarehouseProductItem>.from(_mockProducts));
      }
    }
  }

  Future<void> deleteProduct(String id) async {
    if (isFirebaseActive) {
      await _productsCollection.doc(id).delete();
    } else {
      _mockProducts.removeWhere((p) => p.id == id);
      _productsController.add(List<WarehouseProductItem>.from(_mockProducts));
    }
  }

  // ===================== SEARCH =====================

  Stream<List<WarehouseProductItem>> searchProductsStream(
    String query, {
    String? group,
  }) {
    final cleanQuery = query.trim().toLowerCase();

    if (isFirebaseActive) {
      Query<Map<String, dynamic>> ref = _productsCollection;
      if (group != null && group.isNotEmpty) {
        ref = ref.where("group", isEqualTo: group);
      }
      return ref
          .where(
            'name',
            isGreaterThanOrEqualTo: query,
            isLessThan: query.isEmpty
                ? ''
                : query.substring(0, query.length - 1) +
                    String.fromCharCode(query.codeUnitAt(query.length - 1) + 1),
          )
          .orderBy('name')
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => WarehouseProductItem(
                  id: doc.id,
                  product: Product.fromMap(doc.data()),
                ))
            .toList();
      });
    } else {
      if (cleanQuery.isEmpty) {
        return Stream.value(<WarehouseProductItem>[]);
      }
      final results = _mockProducts.where((item) {
        final matchesGroup = group == null ||
            group.isEmpty ||
            (item.product.group?.toLowerCase() == group.toLowerCase());
        final nameMatches =
            item.product.name?.toLowerCase().contains(cleanQuery) ?? false;
        final companyMatches =
            item.product.company?.toLowerCase().contains(cleanQuery) ?? false;
        return matchesGroup && (nameMatches || companyMatches);
      }).toList();

      return Stream.value(results);
    }
  }
}
