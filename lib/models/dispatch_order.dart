enum DispatchStatus { pending, picking, packed, dispatched, delivered, cancelled }

enum OrderPriority { normal, high, urgent }

class DispatchLineItem {
  const DispatchLineItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    this.pickedQuantity = 0,
    required this.unitPrice,
    this.binLocation = '',
  });

  final String productId;
  final String productName;
  final int quantity;
  final int pickedQuantity;
  final double unitPrice;
  final String binLocation;

  double get subtotal => quantity * unitPrice;
  bool get isFullyPicked => pickedQuantity >= quantity;

  DispatchLineItem copyWith({
    String? productId,
    String? productName,
    int? quantity,
    int? pickedQuantity,
    double? unitPrice,
    String? binLocation,
  }) {
    return DispatchLineItem(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      pickedQuantity: pickedQuantity ?? this.pickedQuantity,
      unitPrice: unitPrice ?? this.unitPrice,
      binLocation: binLocation ?? this.binLocation,
    );
  }
}

class DispatchOrder {
  const DispatchOrder({
    required this.id,
    required this.orderNumber,
    required this.customerName,
    required this.destination,
    required this.createdAt,
    this.status = DispatchStatus.pending,
    this.priority = OrderPriority.normal,
    this.items = const [],
    this.carrier = 'Standard Freight',
    this.trackingNumber = '',
    this.notes = '',
  });

  final String id;
  final String orderNumber;
  final String customerName;
  final String destination;
  final DateTime createdAt;
  final DispatchStatus status;
  final OrderPriority priority;
  final List<DispatchLineItem> items;
  final String carrier;
  final String trackingNumber;
  final String notes;

  double get totalValue => items.fold(0.0, (acc, item) => acc + item.subtotal);
  int get totalQuantity => items.fold(0, (acc, item) => acc + item.quantity);
  int get totalPicked => items.fold(0, (acc, item) => acc + item.pickedQuantity);

  DispatchOrder copyWith({
    String? id,
    String? orderNumber,
    String? customerName,
    String? destination,
    DateTime? createdAt,
    DispatchStatus? status,
    OrderPriority? priority,
    List<DispatchLineItem>? items,
    String? carrier,
    String? trackingNumber,
    String? notes,
  }) {
    return DispatchOrder(
      id: id ?? this.id,
      orderNumber: orderNumber ?? this.orderNumber,
      customerName: customerName ?? this.customerName,
      destination: destination ?? this.destination,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      items: items ?? this.items,
      carrier: carrier ?? this.carrier,
      trackingNumber: trackingNumber ?? this.trackingNumber,
      notes: notes ?? this.notes,
    );
  }
}
