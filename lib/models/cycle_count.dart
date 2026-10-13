import 'package:cloud_firestore/cloud_firestore.dart';

enum CycleCountStatus { scheduled, inProgress, pendingApproval, completed, cancelled }

extension CycleCountStatusX on CycleCountStatus {
  String get label => switch (this) {
        CycleCountStatus.scheduled => 'Scheduled',
        CycleCountStatus.inProgress => 'In Progress',
        CycleCountStatus.pendingApproval => 'Pending Approval',
        CycleCountStatus.completed => 'Completed',
        CycleCountStatus.cancelled => 'Cancelled',
      };
  String get key => name;
  static CycleCountStatus parse(String? s) => CycleCountStatus.values
      .firstWhere((e) => e.name == s, orElse: () => CycleCountStatus.scheduled);
}

/// Reason codes required when variance exceeds tolerance.
enum VarianceReason {
  countError,
  theft,
  damage,
  systemError,
  receiving,
  other,
}

extension VarianceReasonX on VarianceReason {
  String get label => switch (this) {
        VarianceReason.countError => 'Count Error',
        VarianceReason.theft => 'Theft / Loss',
        VarianceReason.damage => 'Damage',
        VarianceReason.systemError => 'System Error',
        VarianceReason.receiving => 'Receiving Error',
        VarianceReason.other => 'Other',
      };
  String get key => name;
  static VarianceReason parse(String? s) => VarianceReason.values
      .firstWhere((e) => e.name == s, orElse: () => VarianceReason.other);
}

class CycleCountItem {
  const CycleCountItem({
    required this.productId,
    required this.productName,
    required this.sku,
    required this.location,
    required this.abcClass,
    required this.systemQty,
    this.countedQty,
    this.unitCost = 0.0,
    this.reasonCode,
    this.reasonNote = '',
    this.countedBy = '',
    this.countedAt,
  });

  final String productId;
  final String productName;
  final String sku;
  final String location;
  final String abcClass; // 'A', 'B', or 'C'
  final int systemQty;
  final int? countedQty; // null = not yet counted
  final double unitCost;
  final VarianceReason? reasonCode; // required when variance > tolerance
  final String reasonNote;
  final String countedBy;
  final DateTime? countedAt;

  int get variance => (countedQty ?? systemQty) - systemQty;
  double get varianceValue => variance * unitCost;
  bool get isCounted => countedQty != null;
  bool get hasDiscrepancy => isCounted && variance != 0;

  CycleCountItem copyWith({
    int? countedQty,
    VarianceReason? reasonCode,
    String? reasonNote,
    String? countedBy,
    DateTime? countedAt,
  }) =>
      CycleCountItem(
        productId: productId,
        productName: productName,
        sku: sku,
        location: location,
        abcClass: abcClass,
        systemQty: systemQty,
        countedQty: countedQty ?? this.countedQty,
        unitCost: unitCost,
        reasonCode: reasonCode ?? this.reasonCode,
        reasonNote: reasonNote ?? this.reasonNote,
        countedBy: countedBy ?? this.countedBy,
        countedAt: countedAt ?? this.countedAt,
      );

  Map<String, dynamic> toMap() => {
        'productId': productId,
        'productName': productName,
        'sku': sku,
        'location': location,
        'abcClass': abcClass,
        'systemQty': systemQty,
        'countedQty': countedQty,
        'unitCost': unitCost,
        'reasonCode': reasonCode?.key,
        'reasonNote': reasonNote,
        'countedBy': countedBy,
        'countedAt': countedAt != null ? Timestamp.fromDate(countedAt!) : null,
      };

  factory CycleCountItem.fromMap(Map<String, dynamic> m) {
    final ct = m['countedAt'];
    return CycleCountItem(
      productId: (m['productId'] as String?) ?? '',
      productName: (m['productName'] as String?) ?? '',
      sku: (m['sku'] as String?) ?? '',
      location: (m['location'] as String?) ?? '',
      abcClass: (m['abcClass'] as String?) ?? 'C',
      systemQty: (m['systemQty'] as num?)?.toInt() ?? 0,
      countedQty: (m['countedQty'] as num?)?.toInt(),
      unitCost: (m['unitCost'] as num?)?.toDouble() ?? 0.0,
      reasonCode: m['reasonCode'] != null
          ? VarianceReasonX.parse(m['reasonCode'] as String?)
          : null,
      reasonNote: (m['reasonNote'] as String?) ?? '',
      countedBy: (m['countedBy'] as String?) ?? '',
      countedAt: ct is Timestamp ? ct.toDate() : null,
    );
  }
}

class CycleCount {
  const CycleCount({
    required this.id,
    required this.countNumber,
    required this.createdBy,
    required this.createdAt,
    this.status = CycleCountStatus.scheduled,
    this.abcFilter = 'A', // which class to count: A, B, C, or All
    this.varianceTolerance = 2, // allowed unit variance before reason required
    this.items = const [],
    this.completedAt,
    this.approvedBy = '',
    this.notes = '',
  });

  final String id;
  final String countNumber;
  final String createdBy;
  final DateTime createdAt;
  final CycleCountStatus status;
  final String abcFilter;
  final int varianceTolerance;
  final List<CycleCountItem> items;
  final DateTime? completedAt;
  final String approvedBy;
  final String notes;

  int get totalItems => items.length;
  int get countedItems => items.where((i) => i.isCounted).length;
  int get discrepancyItems => items.where((i) => i.hasDiscrepancy).length;
  double get netVarianceValue =>
      items.fold(0.0, (acc, i) => acc + i.varianceValue);
  bool get requiresApproval =>
      items.any((i) => i.hasDiscrepancy && i.variance.abs() > varianceTolerance);

  CycleCount copyWith({
    CycleCountStatus? status,
    List<CycleCountItem>? items,
    DateTime? completedAt,
    String? approvedBy,
    String? notes,
  }) =>
      CycleCount(
        id: id,
        countNumber: countNumber,
        createdBy: createdBy,
        createdAt: createdAt,
        status: status ?? this.status,
        abcFilter: abcFilter,
        varianceTolerance: varianceTolerance,
        items: items ?? this.items,
        completedAt: completedAt ?? this.completedAt,
        approvedBy: approvedBy ?? this.approvedBy,
        notes: notes ?? this.notes,
      );

  Map<String, dynamic> toMap() => {
        'countNumber': countNumber,
        'createdBy': createdBy,
        'createdAt': Timestamp.fromDate(createdAt),
        'status': status.key,
        'abcFilter': abcFilter,
        'varianceTolerance': varianceTolerance,
        'items': items.map((i) => i.toMap()).toList(),
        'completedAt':
            completedAt != null ? Timestamp.fromDate(completedAt!) : null,
        'approvedBy': approvedBy,
        'notes': notes,
      };

  factory CycleCount.fromMap(String id, Map<String, dynamic> m) {
    final ca = m['createdAt'];
    final cp = m['completedAt'];
    return CycleCount(
      id: id,
      countNumber: (m['countNumber'] as String?) ?? '',
      createdBy: (m['createdBy'] as String?) ?? '',
      createdAt: ca is Timestamp ? ca.toDate() : DateTime.now(),
      status: CycleCountStatusX.parse(m['status'] as String?),
      abcFilter: (m['abcFilter'] as String?) ?? 'A',
      varianceTolerance: (m['varianceTolerance'] as num?)?.toInt() ?? 2,
      items: ((m['items'] as List?) ?? [])
          .map((e) => CycleCountItem.fromMap(e as Map<String, dynamic>))
          .toList(),
      completedAt: cp is Timestamp ? cp.toDate() : null,
      approvedBy: (m['approvedBy'] as String?) ?? '',
      notes: (m['notes'] as String?) ?? '',
    );
  }
}
