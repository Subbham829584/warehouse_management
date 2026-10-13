enum BatchStatus { active, nearExpiry, expired, quarantined }

class BatchLot {
  const BatchLot({
    required this.id,
    required this.batchNumber, // e.g. LOT-2026-X89
    required this.productId,
    required this.productName,
    required this.sku,
    required this.initialQuantity,
    required this.remainingQuantity,
    required this.manufacturingDate,
    required this.expiryDate,
    required this.storageLocation,
    this.status = BatchStatus.active,
  });

  final String id;
  final String batchNumber;
  final String productId;
  final String productName;
  final String sku;
  final int initialQuantity;
  final int remainingQuantity;
  final DateTime manufacturingDate;
  final DateTime expiryDate;
  final String storageLocation;
  final BatchStatus status;

  int get daysUntilExpiry =>
      expiryDate.difference(DateTime.now()).inDays;

  bool get isExpired => daysUntilExpiry <= 0;
  bool get isNearExpiry => daysUntilExpiry > 0 && daysUntilExpiry <= 45;

  BatchLot copyWith({
    String? id,
    String? batchNumber,
    String? productId,
    String? productName,
    String? sku,
    int? initialQuantity,
    int? remainingQuantity,
    DateTime? manufacturingDate,
    DateTime? expiryDate,
    String? storageLocation,
    BatchStatus? status,
  }) {
    return BatchLot(
      id: id ?? this.id,
      batchNumber: batchNumber ?? this.batchNumber,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      sku: sku ?? this.sku,
      initialQuantity: initialQuantity ?? this.initialQuantity,
      remainingQuantity: remainingQuantity ?? this.remainingQuantity,
      manufacturingDate: manufacturingDate ?? this.manufacturingDate,
      expiryDate: expiryDate ?? this.expiryDate,
      storageLocation: storageLocation ?? this.storageLocation,
      status: status ?? this.status,
    );
  }
}
