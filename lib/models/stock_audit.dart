enum AuditStatus { inProgress, completed, cancelled }

class AuditLineItem {
  const AuditLineItem({
    required this.productId,
    required this.productName,
    required this.sku,
    required this.location,
    required this.systemQuantity,
    required this.countedQuantity,
    this.unitCost = 0.0,
    this.notes = '',
  });

  final String productId;
  final String productName;
  final String sku;
  final String location;
  final int systemQuantity;
  final int countedQuantity;
  final double unitCost;
  final String notes;

  int get variance => countedQuantity - systemQuantity;
  double get varianceValue => variance * unitCost;
  bool get hasDiscrepancy => variance != 0;

  AuditLineItem copyWith({
    String? productId,
    String? productName,
    String? sku,
    String? location,
    int? systemQuantity,
    int? countedQuantity,
    double? unitCost,
    String? notes,
  }) {
    return AuditLineItem(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      sku: sku ?? this.sku,
      location: location ?? this.location,
      systemQuantity: systemQuantity ?? this.systemQuantity,
      countedQuantity: countedQuantity ?? this.countedQuantity,
      unitCost: unitCost ?? this.unitCost,
      notes: notes ?? this.notes,
    );
  }
}

class StockAudit {
  const StockAudit({
    required this.id,
    required this.auditNumber,
    required this.createdAt,
    required this.auditorEmail,
    this.status = AuditStatus.inProgress,
    this.items = const [],
    this.completedAt,
    this.notes = '',
  });

  final String id;
  final String auditNumber;
  final DateTime createdAt;
  final String auditorEmail;
  final AuditStatus status;
  final List<AuditLineItem> items;
  final DateTime? completedAt;
  final String notes;

  int get totalItemsCounted => items.length;
  int get totalDiscrepancies => items.where((i) => i.hasDiscrepancy).length;
  int get netUnitVariance => items.fold(0, (acc, i) => acc + i.variance);
  double get netFinancialVariance => items.fold(0.0, (acc, i) => acc + i.varianceValue);

  StockAudit copyWith({
    String? id,
    String? auditNumber,
    DateTime? createdAt,
    String? auditorEmail,
    AuditStatus? status,
    List<AuditLineItem>? items,
    DateTime? completedAt,
    String? notes,
  }) {
    return StockAudit(
      id: id ?? this.id,
      auditNumber: auditNumber ?? this.auditNumber,
      createdAt: createdAt ?? this.createdAt,
      auditorEmail: auditorEmail ?? this.auditorEmail,
      status: status ?? this.status,
      items: items ?? this.items,
      completedAt: completedAt ?? this.completedAt,
      notes: notes ?? this.notes,
    );
  }
}
