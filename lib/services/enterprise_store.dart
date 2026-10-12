import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:warehouse_management/models/dispatch_order.dart';
import 'package:warehouse_management/models/product.dart';
import 'package:warehouse_management/models/purchase_order.dart';
import 'package:warehouse_management/models/stock_audit.dart';
import 'package:warehouse_management/models/stock_movement.dart';
import 'package:warehouse_management/models/supplier.dart';
import 'package:warehouse_management/models/warehouse_zone.dart';
import 'package:warehouse_management/repositories/inventory_repository.dart';

class EnterpriseStore extends ChangeNotifier {
  EnterpriseStore._() {
    _seedData();
  }

  static final EnterpriseStore instance = EnterpriseStore._();

  List<Supplier> _suppliers = [];
  List<PurchaseOrder> _purchaseOrders = [];
  List<DispatchOrder> _dispatchOrders = [];
  List<WarehouseZone> _zones = [];
  List<StockAudit> _audits = [];

  List<Supplier> get suppliers => List.unmodifiable(_suppliers);
  List<PurchaseOrder> get purchaseOrders => List.unmodifiable(_purchaseOrders);
  List<DispatchOrder> get dispatchOrders => List.unmodifiable(_dispatchOrders);
  List<WarehouseZone> get zones => List.unmodifiable(_zones);
  List<StockAudit> get audits => List.unmodifiable(_audits);

  int get pendingDispatchCount =>
      _dispatchOrders.where((o) => o.status == DispatchStatus.pending || o.status == DispatchStatus.picking).length;

  int get pendingPOCount =>
      _purchaseOrders.where((p) => p.status == POStatus.ordered || p.status == POStatus.partiallyReceived).length;

  // ==================== SUPPLIERS ====================
  void addSupplier(Supplier supplier) {
    _suppliers = [supplier, ..._suppliers];
    notifyListeners();
  }

  void updateSupplier(Supplier supplier) {
    _suppliers = _suppliers.map((s) => s.id == supplier.id ? supplier : s).toList();
    notifyListeners();
  }

  // ==================== PURCHASE ORDERS ====================
  void createPurchaseOrder(PurchaseOrder po) {
    _purchaseOrders = [po, ..._purchaseOrders];
    notifyListeners();
  }

  Future<void> receivePOItems({
    required String poId,
    required String productId,
    required int receiveQty,
    required InventoryRepository repo,
    required String userEmail,
  }) async {
    final idx = _purchaseOrders.indexWhere((p) => p.id == poId);
    if (idx == -1) return;

    final po = _purchaseOrders[idx];
    final updatedItems = po.items.map((item) {
      if (item.productId == productId) {
        final newReceived = (item.receivedQuantity + receiveQty).clamp(0, item.quantity);
        return item.copyWith(receivedQuantity: newReceived);
      }
      return item;
    }).toList();

    final allFullyReceived = updatedItems.every((i) => i.receivedQuantity >= i.quantity);
    final anyReceived = updatedItems.any((i) => i.receivedQuantity > 0);

    final newStatus = allFullyReceived
        ? POStatus.received
        : (anyReceived ? POStatus.partiallyReceived : po.status);

    _purchaseOrders[idx] = po.copyWith(
      items: updatedItems,
      status: newStatus,
    );

    // Increment physical stock in the inventory repository
    await repo.adjustStock(
      productId: productId,
      type: MovementType.stockIn,
      amount: receiveQty,
      userEmail: userEmail,
      note: 'PO ${po.poNumber} Received (+${receiveQty})',
    );

    notifyListeners();
  }

  // ==================== DISPATCH ORDERS ====================
  void createDispatchOrder(DispatchOrder order) {
    _dispatchOrders = [order, ..._dispatchOrders];
    notifyListeners();
  }

  void updateItemPicked({
    required String orderId,
    required String productId,
    required int pickedQty,
  }) {
    final idx = _dispatchOrders.indexWhere((o) => o.id == orderId);
    if (idx == -1) return;

    final order = _dispatchOrders[idx];
    final updatedItems = order.items.map((item) {
      if (item.productId == productId) {
        return item.copyWith(pickedQuantity: pickedQty.clamp(0, item.quantity));
      }
      return item;
    }).toList();

    final allPicked = updatedItems.every((i) => i.pickedQuantity >= i.quantity);
    final newStatus = allPicked ? DispatchStatus.packed : DispatchStatus.picking;

    _dispatchOrders[idx] = order.copyWith(
      items: updatedItems,
      status: order.status == DispatchStatus.pending ? newStatus : order.status,
    );
    notifyListeners();
  }

  Future<void> dispatchOrder({
    required String orderId,
    required InventoryRepository repo,
    required String userEmail,
  }) async {
    final idx = _dispatchOrders.indexWhere((o) => o.id == orderId);
    if (idx == -1) return;

    final order = _dispatchOrders[idx];

    // Decrement physical stock in repo for all order line items
    for (final item in order.items) {
      await repo.adjustStock(
        productId: item.productId,
        type: MovementType.stockOut,
        amount: item.quantity,
        userEmail: userEmail,
        note: 'Dispatched Order #${order.orderNumber} (-${item.quantity})',
      );
    }

    _dispatchOrders[idx] = order.copyWith(
      status: DispatchStatus.dispatched,
      trackingNumber: order.trackingNumber.isEmpty
          ? 'TRK-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}'
          : order.trackingNumber,
    );
    notifyListeners();
  }

  // ==================== STOCK AUDIT ====================
  void startAudit(List<ProductItem> currentProducts, String auditorEmail) {
    final auditNumber = 'AUD-${DateTime.now().year}-${100 + _audits.length + 1}';
    final lineItems = currentProducts.map((item) {
      return AuditLineItem(
        productId: item.id,
        productName: item.product.name,
        sku: item.product.sku.isNotEmpty ? item.product.sku : 'SKU-${item.id.substring(0, 4)}',
        location: item.product.location.isNotEmpty ? item.product.location : 'Zone A / Rack 1',
        systemQuantity: item.product.quantity,
        countedQuantity: item.product.quantity, // starts aligned
        unitCost: item.product.cost,
      );
    }).toList();

    final audit = StockAudit(
      id: 'aud_${DateTime.now().millisecondsSinceEpoch}',
      auditNumber: auditNumber,
      createdAt: DateTime.now(),
      auditorEmail: auditorEmail,
      items: lineItems,
    );

    _audits = [audit, ..._audits];
    notifyListeners();
  }

  void updateCountedQuantity({
    required String auditId,
    required String productId,
    required int countedQty,
  }) {
    final idx = _audits.indexWhere((a) => a.id == auditId);
    if (idx == -1) return;

    final audit = _audits[idx];
    final updatedItems = audit.items.map((i) {
      if (i.productId == productId) {
        return i.copyWith(countedQuantity: countedQty < 0 ? 0 : countedQty);
      }
      return i;
    }).toList();

    _audits[idx] = audit.copyWith(items: updatedItems);
    notifyListeners();
  }

  Future<void> reconcileAudit({
    required String auditId,
    required InventoryRepository repo,
    required String userEmail,
  }) async {
    final idx = _audits.indexWhere((a) => a.id == auditId);
    if (idx == -1) return;

    final audit = _audits[idx];

    // For any item with a variance, apply stock take adjustment
    for (final item in audit.items) {
      if (item.hasDiscrepancy) {
        await repo.adjustStock(
          productId: item.productId,
          type: MovementType.adjustment,
          amount: item.countedQuantity,
          userEmail: userEmail,
          note: 'Audit ${audit.auditNumber} Reconciliation: counted ${item.countedQuantity} (var: ${item.variance > 0 ? '+${item.variance}' : item.variance})',
        );
      }
    }

    _audits[idx] = audit.copyWith(
      status: AuditStatus.completed,
      completedAt: DateTime.now(),
    );
    notifyListeners();
  }

  // ==================== SEED INITIAL DEMO DATA ====================
  void _seedData() {
    _suppliers = [
      const Supplier(
        id: 'sup_1',
        name: 'Apex Precision Logistics & Tech',
        contactPerson: 'David Miller',
        email: 'sales@apexprecision.com',
        phone: '+1 (555) 382-9912',
        category: 'Electronics & Chips',
        leadTimeDays: 4,
        rating: 4.9,
        address: '420 Tech Way, Austin, TX',
      ),
      const Supplier(
        id: 'sup_2',
        name: 'Global Pack & Materials Corp',
        contactPerson: 'Elena Rossi',
        email: 'contact@globalpack.org',
        phone: '+1 (555) 714-8833',
        category: 'Packaging & Cartons',
        leadTimeDays: 2,
        rating: 4.7,
        address: '88 Industrial Park, Chicago, IL',
      ),
      const Supplier(
        id: 'sup_3',
        name: 'Nexus Heavy Motors & Parts',
        contactPerson: 'Kavita Sharma',
        email: 'orders@nexusparts.co',
        phone: '+1 (555) 902-1144',
        category: 'Machinery & Hardware',
        leadTimeDays: 7,
        rating: 4.8,
        address: '15 Harbor Blvd, Newark, NJ',
      ),
      const Supplier(
        id: 'sup_4',
        name: 'Quantum Thermal Storage Co',
        contactPerson: 'Marcus Vance',
        email: 'vance@quantumthermal.io',
        phone: '+1 (555) 438-6621',
        category: 'Cold Chain Equipment',
        leadTimeDays: 5,
        rating: 4.6,
        address: '102 Polaris Ave, Seattle, WA',
      ),
    ];

    _purchaseOrders = [
      PurchaseOrder(
        id: 'po_101',
        poNumber: 'PO-2026-081',
        supplierId: 'sup_1',
        supplierName: 'Apex Precision Logistics & Tech',
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        expectedDate: DateTime.now().add(const Duration(days: 2)),
        status: POStatus.ordered,
        items: const [
          POLineItem(
            productId: 'demo_1',
            productName: 'USB-C Fast Charging Cable 2m',
            quantity: 150,
            receivedQuantity: 0,
            unitCost: 3.50,
          ),
          POLineItem(
            productId: 'demo_2',
            productName: 'Wireless Bluetooth Mouse',
            quantity: 80,
            receivedQuantity: 0,
            unitCost: 12.00,
          ),
        ],
        notes: 'Priority air freight. Inspect packaging on arrival.',
      ),
      PurchaseOrder(
        id: 'po_102',
        poNumber: 'PO-2026-079',
        supplierId: 'sup_2',
        supplierName: 'Global Pack & Materials Corp',
        createdAt: DateTime.now().subtract(const Duration(days: 6)),
        expectedDate: DateTime.now().subtract(const Duration(days: 1)),
        status: POStatus.partiallyReceived,
        items: const [
          POLineItem(
            productId: 'demo_3',
            productName: 'Ergonomic Desk Mat (Leather)',
            quantity: 100,
            receivedQuantity: 60,
            unitCost: 8.50,
          ),
        ],
        notes: 'Partial batch cleared. Remaining 40 units in transit.',
      ),
      PurchaseOrder(
        id: 'po_103',
        poNumber: 'PO-2026-068',
        supplierId: 'sup_3',
        supplierName: 'Nexus Heavy Motors & Parts',
        createdAt: DateTime.now().subtract(const Duration(days: 14)),
        expectedDate: DateTime.now().subtract(const Duration(days: 8)),
        status: POStatus.received,
        items: const [
          POLineItem(
            productId: 'demo_4',
            productName: 'Steel Pallet Jack 2.5T',
            quantity: 4,
            receivedQuantity: 4,
            unitCost: 280.00,
          ),
        ],
        notes: 'All units received, quality audit signed off.',
      ),
    ];

    _dispatchOrders = [
      DispatchOrder(
        id: 'do_201',
        orderNumber: 'DSP-9842',
        customerName: 'TechNova Retail Hub',
        destination: 'Dallas Distribution Center, TX',
        createdAt: DateTime.now().subtract(const Duration(hours: 4)),
        status: DispatchStatus.picking,
        priority: OrderPriority.urgent,
        items: const [
          DispatchLineItem(
            productId: 'demo_1',
            productName: 'USB-C Fast Charging Cable 2m',
            quantity: 25,
            pickedQuantity: 25,
            unitPrice: 6.99,
            binLocation: 'A-01-02',
          ),
          DispatchLineItem(
            productId: 'demo_2',
            productName: 'Wireless Bluetooth Mouse',
            quantity: 15,
            pickedQuantity: 10,
            unitPrice: 22.50,
            binLocation: 'A-02-04',
          ),
        ],
        carrier: 'FedEx Express Freight',
        trackingNumber: 'FX-849204821',
        notes: 'Rush delivery required before 10 AM tomorrow.',
      ),
      DispatchOrder(
        id: 'do_202',
        orderNumber: 'DSP-9843',
        customerName: 'Metropolis Workspace Supplies',
        destination: 'Denver Regional Hub, CO',
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        status: DispatchStatus.pending,
        priority: OrderPriority.normal,
        items: const [
          DispatchLineItem(
            productId: 'demo_3',
            productName: 'Ergonomic Desk Mat (Leather)',
            quantity: 12,
            pickedQuantity: 0,
            unitPrice: 16.00,
            binLocation: 'B-03-01',
          ),
        ],
        carrier: 'Standard Road Transport',
        trackingNumber: '',
        notes: 'Deliver to loading bay 3.',
      ),
      DispatchOrder(
        id: 'do_200',
        orderNumber: 'DSP-9830',
        customerName: 'BlueSky Electronics Corp',
        destination: 'Miami Port Logistics, FL',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        status: DispatchStatus.dispatched,
        priority: OrderPriority.high,
        items: const [
          DispatchLineItem(
            productId: 'demo_1',
            productName: 'USB-C Fast Charging Cable 2m',
            quantity: 50,
            pickedQuantity: 50,
            unitPrice: 6.99,
            binLocation: 'A-01-02',
          ),
        ],
        carrier: 'DHL Global Logistics',
        trackingNumber: 'DHL-398110992',
        notes: 'Departed central dock gate 4.',
      ),
    ];

    _zones = [
      const WarehouseZone(
        zoneCode: 'Zone A',
        name: 'High-Density Electronics & Peripherals',
        type: 'Ambient / Temperature Regulated',
        totalCapacity: 1200,
        occupiedCapacity: 890,
        temperatureC: 21.5,
        bins: [
          WarehouseBin(binCode: 'A-01-01', aisle: 'Aisle 1', shelf: 'Tier 1', capacity: 150, occupiedUnits: 120, primaryCategory: 'Cables & Adapters'),
          WarehouseBin(binCode: 'A-01-02', aisle: 'Aisle 1', shelf: 'Tier 2', capacity: 150, occupiedUnits: 145, primaryCategory: 'Cables & Adapters'),
          WarehouseBin(binCode: 'A-02-01', aisle: 'Aisle 2', shelf: 'Tier 1', capacity: 200, occupiedUnits: 160, primaryCategory: 'Peripherals'),
          WarehouseBin(binCode: 'A-02-02', aisle: 'Aisle 2', shelf: 'Tier 2', capacity: 200, occupiedUnits: 80, primaryCategory: 'Peripherals'),
          WarehouseBin(binCode: 'A-03-01', aisle: 'Aisle 3', shelf: 'Tier 1', capacity: 250, occupiedUnits: 210, primaryCategory: 'Audio & Wireless'),
          WarehouseBin(binCode: 'A-03-02', aisle: 'Aisle 3', shelf: 'Tier 2', capacity: 250, occupiedUnits: 175, primaryCategory: 'Audio & Wireless'),
        ],
      ),
      const WarehouseZone(
        zoneCode: 'Zone B',
        name: 'Fast-Moving Office & Workspace Gear',
        type: 'Standard Racking',
        totalCapacity: 800,
        occupiedCapacity: 520,
        temperatureC: 23.0,
        bins: [
          WarehouseBin(binCode: 'B-01-01', aisle: 'Aisle 1', shelf: 'Tier 1', capacity: 200, occupiedUnits: 180, primaryCategory: 'Desk Mats & Stands'),
          WarehouseBin(binCode: 'B-01-02', aisle: 'Aisle 1', shelf: 'Tier 2', capacity: 200, occupiedUnits: 120, primaryCategory: 'Desk Mats & Stands'),
          WarehouseBin(binCode: 'B-02-01', aisle: 'Aisle 2', shelf: 'Tier 1', capacity: 200, occupiedUnits: 110, primaryCategory: 'Packaging'),
          WarehouseBin(binCode: 'B-02-02', aisle: 'Aisle 2', shelf: 'Tier 2', capacity: 200, occupiedUnits: 110, primaryCategory: 'Packaging'),
        ],
      ),
      const WarehouseZone(
        zoneCode: 'Zone C',
        name: 'Bulk Pallets & Heavy Equipment',
        type: 'Heavy Duty Floor & Pallet Racks',
        totalCapacity: 450,
        occupiedCapacity: 280,
        temperatureC: 24.5,
        bins: [
          WarehouseBin(binCode: 'C-01-P1', aisle: 'Aisle 1', shelf: 'Floor Bay', capacity: 150, occupiedUnits: 100, primaryCategory: 'Machinery'),
          WarehouseBin(binCode: 'C-01-P2', aisle: 'Aisle 1', shelf: 'Floor Bay', capacity: 150, occupiedUnits: 90, primaryCategory: 'Bulk Storage'),
          WarehouseBin(binCode: 'C-02-P1', aisle: 'Aisle 2', shelf: 'Floor Bay', capacity: 150, occupiedUnits: 90, primaryCategory: 'Spare Parts'),
        ],
      ),
    ];
  }
}
