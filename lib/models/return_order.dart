enum RmaStatus { requested, inspecting, restocked, quarantined, scrapped }

enum ReturnReason { defective, wrongItem, customerRemorse, damagedInTransit }

class ReturnOrder {
  const ReturnOrder({
    required this.id,
    required this.rmaNumber,
    required this.customerName,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.reason,
    required this.createdAt,
    this.status = RmaStatus.requested,
    this.inspectionNotes = '',
    this.resolvedAt,
    this.refundAmount = 0.0,
  });

  final String id;
  final String rmaNumber;
  final String customerName;
  final String productId;
  final String productName;
  final int quantity;
  final ReturnReason reason;
  final DateTime createdAt;
  final RmaStatus status;
  final String inspectionNotes;
  final DateTime? resolvedAt;
  final double refundAmount;

  ReturnOrder copyWith({
    String? id,
    String? rmaNumber,
    String? customerName,
    String? productId,
    String? productName,
    int? quantity,
    ReturnReason? reason,
    DateTime? createdAt,
    RmaStatus? status,
    String? inspectionNotes,
    DateTime? resolvedAt,
    double? refundAmount,
  }) {
    return ReturnOrder(
      id: id ?? this.id,
      rmaNumber: rmaNumber ?? this.rmaNumber,
      customerName: customerName ?? this.customerName,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      reason: reason ?? this.reason,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      inspectionNotes: inspectionNotes ?? this.inspectionNotes,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      refundAmount: refundAmount ?? this.refundAmount,
    );
  }
}
