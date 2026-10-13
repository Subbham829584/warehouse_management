enum POStatus { draft, ordered, partiallyReceived, received, cancelled }

class POLineItem {
  const POLineItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    this.receivedQuantity = 0,
    required this.unitCost,
  });

  final String productId;
  final String productName;
  final int quantity;
  final int receivedQuantity;
  final double unitCost;

  double get subtotal => quantity * unitCost;

  POLineItem copyWith({
    String? productId,
    String? productName,
    int? quantity,
    int? receivedQuantity,
    double? unitCost,
  }) {
    return POLineItem(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      receivedQuantity: receivedQuantity ?? this.receivedQuantity,
      unitCost: unitCost ?? this.unitCost,
    );
  }

  Map<String, dynamic> toMap() => {
        'productId': productId,
        'productName': productName,
        'quantity': quantity,
        'receivedQuantity': receivedQuantity,
        'unitCost': unitCost,
      };

  factory POLineItem.fromMap(Map<String, dynamic> map) => POLineItem(
        productId: map['productId'] as String? ?? '',
        productName: map['productName'] as String? ?? '',
        quantity: (map['quantity'] as num?)?.toInt() ?? 0,
        receivedQuantity: (map['receivedQuantity'] as num?)?.toInt() ?? 0,
        unitCost: (map['unitCost'] as num?)?.toDouble() ?? 0.0,
      );
}

class PurchaseOrder {
  const PurchaseOrder({
    required this.id,
    required this.poNumber,
    required this.supplierId,
    required this.supplierName,
    required this.createdAt,
    required this.expectedDate,
    this.status = POStatus.ordered,
    this.items = const [],
    this.notes = '',
  });

  final String id;
  final String poNumber;
  final String supplierId;
  final String supplierName;
  final DateTime createdAt;
  final DateTime expectedDate;
  final POStatus status;
  final List<POLineItem> items;
  final String notes;

  double get totalAmount => items.fold(0.0, (acc, item) => acc + item.subtotal);
  int get totalQuantity => items.fold(0, (acc, item) => acc + item.quantity);
  int get totalReceived => items.fold(0, (acc, item) => acc + item.receivedQuantity);

  PurchaseOrder copyWith({
    String? id,
    String? poNumber,
    String? supplierId,
    String? supplierName,
    DateTime? createdAt,
    DateTime? expectedDate,
    POStatus? status,
    List<POLineItem>? items,
    String? notes,
  }) {
    return PurchaseOrder(
      id: id ?? this.id,
      poNumber: poNumber ?? this.poNumber,
      supplierId: supplierId ?? this.supplierId,
      supplierName: supplierName ?? this.supplierName,
      createdAt: createdAt ?? this.createdAt,
      expectedDate: expectedDate ?? this.expectedDate,
      status: status ?? this.status,
      items: items ?? this.items,
      notes: notes ?? this.notes,
    );
  }
}
