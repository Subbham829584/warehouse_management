import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:warehouse_management/models/app_notification.dart';
import 'package:warehouse_management/models/app_user.dart';
import 'package:warehouse_management/models/cycle_count.dart';
import 'package:warehouse_management/models/grn.dart';
import 'package:warehouse_management/models/pick_list.dart';
import 'package:warehouse_management/models/product.dart';
import 'package:warehouse_management/repositories/inventory_repository.dart';

/// WMS Service — singleton that manages GRN, cycle counts, pick lists,
/// put-away, reorder suggestions, roles, and notifications.
/// Keeps state in memory (in-sync with Firestore when online).
class WmsService extends ChangeNotifier {
  WmsService._();
  static final WmsService instance = WmsService._();

  // --- State ---------------------------------------------------------------
  final List<GoodsReceivedNote> _grns = [];
  final List<CycleCount> _cycleCounts = [];
  final List<PickList> _pickLists = [];
  final List<AppNotification> _notifications = [];
  final List<AppUser> _users = [];

  // --- Expose read-only views -----------------------------------------------
  List<GoodsReceivedNote> get grns => List.unmodifiable(_grns);
  List<CycleCount> get cycleCounts => List.unmodifiable(_cycleCounts);
  List<PickList> get pickLists => List.unmodifiable(_pickLists);
  List<AppNotification> get notifications => List.unmodifiable(_notifications);
  List<AppNotification> get unreadNotifications =>
      _notifications.where((n) => !n.isRead).toList();
  List<AppUser> get users => List.unmodifiable(_users);

  // --- Seed demo data -------------------------------------------------------
  bool _seeded = false;

  void seedDemo(List<ProductItem> products) {
    if (_seeded) return;
    _seeded = true;

    // Seed demo users
    _users.addAll([
      const AppUser(
          uid: 'u1',
          email: 'admin@warehouse.io',
          displayName: 'Ravi Admin',
          role: UserRole.admin),
      const AppUser(
          uid: 'u2',
          email: 'manager@warehouse.io',
          displayName: 'Priya Manager',
          role: UserRole.manager),
      const AppUser(
          uid: 'u3',
          email: 'picker@warehouse.io',
          displayName: 'Amit Picker',
          role: UserRole.picker),
    ]);

    // Seed demo GRN
    if (products.isNotEmpty) {
      final p = products.first;
      _grns.add(GoodsReceivedNote(
        id: 'grn_1',
        grnNumber: 'GRN-2026-001',
        poId: 'po_demo',
        poNumber: 'PO-2026-101',
        supplierId: 'sup_1',
        supplierName: 'Zebra Tech',
        receivedBy: 'admin@warehouse.io',
        receivedAt: DateTime.now().subtract(const Duration(days: 2)),
        status: GrnStatus.completed,
        items: [
          GrnLineItem(
            productId: p.id,
            productName: p.product.name,
            sku: p.product.sku,
            orderedQty: 50,
            receivedQty: 48,
            lotNumber: 'LOT-2026-A01',
            discrepancyReason: '2 units damaged in transit',
            putAwayBin: 'A-01-S1',
          ),
        ],
      ));
    }

    // Seed demo cycle count
    if (products.isNotEmpty) {
      _cycleCounts.add(CycleCount(
        id: 'cc_1',
        countNumber: 'CC-2026-001',
        createdBy: 'manager@warehouse.io',
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        status: CycleCountStatus.inProgress,
        abcFilter: 'A',
        varianceTolerance: 2,
        items: products.take(3).map((p) => CycleCountItem(
              productId: p.id,
              productName: p.product.name,
              sku: p.product.sku,
              location: p.product.location,
              abcClass: 'A',
              systemQty: p.product.quantity,
              unitCost: p.product.cost,
            )).toList(),
      ));
    }

    // Seed demo pick list
    if (products.length >= 2) {
      _pickLists.add(PickList(
        id: 'pl_1',
        pickNumber: 'PICK-2026-001',
        orderId: 'ORD-5001',
        customerName: 'Tech Solutions Pvt Ltd',
        assignedTo: 'picker@warehouse.io',
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        status: PickStatus.pending,
        filterZone: 'Zone A',
        items: [
          PickLineItem(
            productId: products[0].id,
            productName: products[0].product.name,
            sku: products[0].product.sku,
            zone: 'Zone A',
            binCode: 'A-01-S1',
            qtyRequired: 5,
            lotNumber: 'LOT-2026-A01',
          ),
          PickLineItem(
            productId: products[1].id,
            productName: products[1].product.name,
            sku: products[1].product.sku,
            zone: 'Zone A',
            binCode: 'A-02-S2',
            qtyRequired: 2,
          ),
        ],
      ));
    }

    // Seed notifications
    _seedNotifications(products);

    notifyListeners();
  }

  void _seedNotifications(List<ProductItem> products) {
    final now = DateTime.now();
    final lowStock = products.where((p) => p.product.isLowStock).take(3);
    for (final p in lowStock) {
      _notifications.add(AppNotification(
        id: 'notif_low_${p.id}',
        type: NotifType.lowStock,
        title: 'Low Stock: ${p.product.name}',
        body:
            'Only ${p.product.quantity} ${p.product.unit} remaining (min: ${p.product.minStock})',
        createdAt: now.subtract(const Duration(minutes: 30)),
        referenceId: p.id,
      ));
    }
    _notifications.add(AppNotification(
      id: 'notif_cc1',
      type: NotifType.cycleCountDue,
      title: 'Class A Cycle Count Due',
      body: 'Class A products have not been counted in 7 days',
      createdAt: now.subtract(const Duration(hours: 2)),
    ));
    _notifications.add(AppNotification(
      id: 'notif_reorder1',
      type: NotifType.reorderSuggestion,
      title: 'Reorder Suggested',
      body: 'Stock levels for 2 items are below reorder point',
      createdAt: now.subtract(const Duration(hours: 5)),
    ));
  }

  // --- PUT-AWAY RULES -------------------------------------------------------
  /// Suggests a bin for a product based on simple velocity + category rules.
  /// Real systems query zone capacity; we use a deterministic rule set.
  String suggestBin(String productGroup, int quantity) {
    // Map product groups to zones
    if (productGroup.toLowerCase().contains('electronic')) {
      return quantity > 50 ? 'A-01-S1' : 'A-02-S2';
    } else if (productGroup.toLowerCase().contains('industrial') ||
        productGroup.toLowerCase().contains('tool')) {
      return 'B-01-S1';
    } else if (productGroup.toLowerCase().contains('pack')) {
      return 'C-01-S1';
    } else if (productGroup.toLowerCase().contains('safety') ||
        productGroup.toLowerCase().contains('ppe')) {
      return 'B-02-S2';
    } else if (productGroup.toLowerCase().contains('hardware') ||
        productGroup.toLowerCase().contains('fastener')) {
      return 'C-02-S1';
    }
    return 'D-01-S1'; // general bin
  }

  // --- GRN -----------------------------------------------------------------
  void createGrn(GoodsReceivedNote grn) {
    _grns.insert(0, grn);
    notifyListeners();
  }

  void updateGrn(GoodsReceivedNote grn) {
    final i = _grns.indexWhere((g) => g.id == grn.id);
    if (i != -1) {
      _grns[i] = grn;
      notifyListeners();
    }
  }

  /// Completes a GRN and calls repo.adjustStock for each received item.
  Future<void> completeGrn({
    required String grnId,
    required InventoryRepository repo,
    required String userEmail,
  }) async {
    final i = _grns.indexWhere((g) => g.id == grnId);
    if (i == -1) return;
    final grn = _grns[i];
    for (final item in grn.items) {
      if (item.receivedQty > 0) {
        await repo.adjustStock(
          productId: item.productId,
          type: MovementType.stockIn,
          amount: item.receivedQty,
          userEmail: userEmail,
          note: 'GRN ${grn.grnNumber} | Lot: ${item.lotNumber} | Put-away: ${item.putAwayBin}',
        );
      }
    }
    final finalStatus = grn.hasDiscrepancies ? GrnStatus.discrepancy : GrnStatus.completed;
    _grns[i] = grn.copyWith(status: finalStatus, completedAt: DateTime.now());
    notifyListeners();
  }

  // --- CYCLE COUNT ----------------------------------------------------------
  void createCycleCount(CycleCount cc) {
    _cycleCounts.insert(0, cc);
    notifyListeners();
  }

  void updateCycleCountItem({
    required String countId,
    required String productId,
    required int countedQty,
    VarianceReason? reason,
    String reasonNote = '',
    required String countedBy,
  }) {
    final ci = _cycleCounts.indexWhere((c) => c.id == countId);
    if (ci == -1) return;
    final cc = _cycleCounts[ci];
    final items = cc.items.map((item) {
      if (item.productId != productId) return item;
      return item.copyWith(
        countedQty: countedQty,
        reasonCode: reason,
        reasonNote: reasonNote,
        countedBy: countedBy,
        countedAt: DateTime.now(),
      );
    }).toList();
    _cycleCounts[ci] = cc.copyWith(items: items);
    notifyListeners();
  }

  /// Approves a cycle count — commits all variances to inventory.
  Future<void> approveCycleCount({
    required String countId,
    required InventoryRepository repo,
    required String approverEmail,
  }) async {
    final ci = _cycleCounts.indexWhere((c) => c.id == countId);
    if (ci == -1) return;
    final cc = _cycleCounts[ci];
    for (final item in cc.items) {
      if (item.isCounted && item.hasDiscrepancy) {
        await repo.adjustStock(
          productId: item.productId,
          type: MovementType.adjustment,
          amount: item.countedQty!,
          userEmail: approverEmail,
          note:
              'Cycle Count ${cc.countNumber} | Reason: ${item.reasonCode?.label ?? "None"}',
        );
      }
    }
    _cycleCounts[ci] = cc.copyWith(
      status: CycleCountStatus.completed,
      completedAt: DateTime.now(),
      approvedBy: approverEmail,
    );
    notifyListeners();
  }

  // --- PICK LISTS -----------------------------------------------------------
  void createPickList(PickList pl) {
    _pickLists.insert(0, pl);
    notifyListeners();
  }

  void markItemPicked({
    required String pickListId,
    required String productId,
    required int qtyPicked,
  }) {
    final pi = _pickLists.indexWhere((p) => p.id == pickListId);
    if (pi == -1) return;
    final pl = _pickLists[pi];
    final items = pl.items.map((item) {
      if (item.productId != productId) return item;
      return item.copyWith(qtyPicked: qtyPicked, isPicked: true);
    }).toList();
    final allDone = items.every((i) => i.isPicked);
    _pickLists[pi] = pl.copyWith(
      items: items,
      status: allDone ? PickStatus.completed : PickStatus.inProgress,
      completedAt: allDone ? DateTime.now() : null,
    );
    notifyListeners();
  }

  // --- NOTIFICATIONS --------------------------------------------------------
  void markNotificationRead(String id) {
    final i = _notifications.indexWhere((n) => n.id == id);
    if (i == -1) return;
    _notifications[i] = _notifications[i].markRead();
    notifyListeners();
  }

  void markAllRead() {
    for (var i = 0; i < _notifications.length; i++) {
      _notifications[i] = _notifications[i].markRead();
    }
    notifyListeners();
  }

  void addNotification(AppNotification notif) {
    _notifications.insert(0, notif);
    notifyListeners();
  }

  /// Scan products for low stock and generate notifications.
  void checkAndGenerateNotifications(List<ProductItem> products) {
    final now = DateTime.now();
    for (final p in products) {
      if (p.product.isLowStock) {
        final existingId = 'notif_low_${p.id}';
        if (!_notifications.any((n) => n.id == existingId)) {
          _notifications.insert(
            0,
            AppNotification(
              id: existingId,
              type: NotifType.lowStock,
              title: 'Low Stock: ${p.product.name}',
              body:
                  'Only ${p.product.quantity} ${p.product.unit} remaining (min: ${p.product.minStock})',
              createdAt: now,
              referenceId: p.id,
            ),
          );
        }
      }
    }
    notifyListeners();
  }

  // --- USER MANAGEMENT ------------------------------------------------------
  AppUser? getUserByEmail(String email) {
    try {
      return _users.firstWhere(
          (u) => u.email.toLowerCase() == email.toLowerCase());
    } catch (_) {
      return null;
    }
  }

  /// Load user role from Firestore for real auth.
  Future<UserRole> fetchUserRole(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserRoleX.parse(doc.data()?['role'] as String?);
      }
    } catch (_) {}
    return UserRole.picker; // safe default
  }

  Future<void> updateUserRole(String uid, UserRole role) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({'role': role.key});
    } catch (_) {}
    final i = _users.indexWhere((u) => u.uid == uid);
    if (i != -1) {
      _users[i] = _users[i].copyWith(role: role);
    }
    notifyListeners();
  }

  Future<List<AppUser>> fetchAllUsers(String warehouseId) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .where('warehouseId', isEqualTo: warehouseId)
          .get();
      _users.clear();
      _users.addAll(
        snap.docs.map((d) => AppUser.fromMap(d.id, d.data())).toList(),
      );
      notifyListeners();
    } catch (_) {}
    return List.unmodifiable(_users);
  }
}
