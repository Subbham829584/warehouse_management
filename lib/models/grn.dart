import 'package:cloud_firestore/cloud_firestore.dart';

/// GRN status tracks the receiving lifecycle.
enum GrnStatus { draft, inProgress, completed, discrepancy }

extension GrnStatusX on GrnStatus {
  String get label => switch (this) {
        GrnStatus.draft => 'Draft',
        GrnStatus.inProgress => 'In Progress',
        GrnStatus.completed => 'Completed',
        GrnStatus.discrepancy => 'Discrepancy',
      };
  String get key => name;
  static GrnStatus parse(String? s) => GrnStatus.values
      .firstWhere((e) => e.name == s, orElse: () => GrnStatus.draft);
}

/// One line in a GRN receipt — maps to a PO line item.
class GrnLineItem {
  const GrnLineItem({
    required this.productId,
    required this.productName,
    required this.sku,
    required this.orderedQty,
    this.receivedQty = 0,
    this.lotNumber = '',
    this.expiryDate,
    this.discrepancyReason = '',
    this.putAwayBin = '',
  });

  final String productId;
  final String productName;
  final String sku;
  final int orderedQty;
  final int receivedQty;
  final String lotNumber;
  final DateTime? expiryDate;
  final String discrepancyReason; // required when receivedQty != orderedQty
  final String putAwayBin;       // bin suggested by put-away rules

  int get variance => receivedQty - orderedQty;
  bool get hasDiscrepancy => variance != 0;

  GrnLineItem copyWith({
    int? receivedQty,
    String? lotNumber,
    DateTime? expiryDate,
    String? discrepancyReason,
    String? putAwayBin,
  }) =>
      GrnLineItem(
        productId: productId,
        productName: productName,
        sku: sku,
        orderedQty: orderedQty,
        receivedQty: receivedQty ?? this.receivedQty,
        lotNumber: lotNumber ?? this.lotNumber,
        expiryDate: expiryDate ?? this.expiryDate,
        discrepancyReason: discrepancyReason ?? this.discrepancyReason,
        putAwayBin: putAwayBin ?? this.putAwayBin,
      );

  Map<String, dynamic> toMap() => {
        'productId': productId,
        'productName': productName,
        'sku': sku,
        'orderedQty': orderedQty,
        'receivedQty': receivedQty,
        'lotNumber': lotNumber,
        'expiryDate': expiryDate?.toIso8601String(),
        'discrepancyReason': discrepancyReason,
        'putAwayBin': putAwayBin,
      };

  factory GrnLineItem.fromMap(Map<String, dynamic> m) => GrnLineItem(
        productId: (m['productId'] as String?) ?? '',
        productName: (m['productName'] as String?) ?? '',
        sku: (m['sku'] as String?) ?? '',
        orderedQty: (m['orderedQty'] as num?)?.toInt() ?? 0,
        receivedQty: (m['receivedQty'] as num?)?.toInt() ?? 0,
        lotNumber: (m['lotNumber'] as String?) ?? '',
        expiryDate: m['expiryDate'] != null
            ? DateTime.tryParse(m['expiryDate'] as String)
            : null,
        discrepancyReason: (m['discrepancyReason'] as String?) ?? '',
        putAwayBin: (m['putAwayBin'] as String?) ?? '',
      );
}

/// Goods Received Note — connects a PO to actual physical receipt.
class GoodsReceivedNote {
  const GoodsReceivedNote({
    required this.id,
    required this.grnNumber,
    required this.poId,
    required this.poNumber,
    required this.supplierId,
    required this.supplierName,
    required this.receivedBy,
    required this.receivedAt,
    this.status = GrnStatus.inProgress,
    this.items = const [],
    this.notes = '',
    this.completedAt,
  });

  final String id;
  final String grnNumber;
  final String poId;
  final String poNumber;
  final String supplierId;
  final String supplierName;
  final String receivedBy;
  final DateTime receivedAt;
  final GrnStatus status;
  final List<GrnLineItem> items;
  final String notes;
  final DateTime? completedAt;

  int get totalOrdered => items.fold(0, (acc, i) => acc + i.orderedQty);
  int get totalReceived => items.fold(0, (acc, i) => acc + i.receivedQty);
  bool get hasDiscrepancies => items.any((i) => i.hasDiscrepancy);

  GoodsReceivedNote copyWith({
    GrnStatus? status,
    List<GrnLineItem>? items,
    DateTime? completedAt,
    String? notes,
  }) =>
      GoodsReceivedNote(
        id: id,
        grnNumber: grnNumber,
        poId: poId,
        poNumber: poNumber,
        supplierId: supplierId,
        supplierName: supplierName,
        receivedBy: receivedBy,
        receivedAt: receivedAt,
        status: status ?? this.status,
        items: items ?? this.items,
        notes: notes ?? this.notes,
        completedAt: completedAt ?? this.completedAt,
      );

  Map<String, dynamic> toMap() => {
        'grnNumber': grnNumber,
        'poId': poId,
        'poNumber': poNumber,
        'supplierId': supplierId,
        'supplierName': supplierName,
        'receivedBy': receivedBy,
        'receivedAt': Timestamp.fromDate(receivedAt),
        'status': status.key,
        'items': items.map((i) => i.toMap()).toList(),
        'notes': notes,
        'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      };

  factory GoodsReceivedNote.fromMap(String id, Map<String, dynamic> m) {
    final ts = m['receivedAt'];
    final ct = m['completedAt'];
    return GoodsReceivedNote(
      id: id,
      grnNumber: (m['grnNumber'] as String?) ?? '',
      poId: (m['poId'] as String?) ?? '',
      poNumber: (m['poNumber'] as String?) ?? '',
      supplierId: (m['supplierId'] as String?) ?? '',
      supplierName: (m['supplierName'] as String?) ?? '',
      receivedBy: (m['receivedBy'] as String?) ?? '',
      receivedAt: ts is Timestamp ? ts.toDate() : DateTime.now(),
      status: GrnStatusX.parse(m['status'] as String?),
      items: ((m['items'] as List?) ?? [])
          .map((e) => GrnLineItem.fromMap(e as Map<String, dynamic>))
          .toList(),
      notes: (m['notes'] as String?) ?? '',
      completedAt: ct is Timestamp ? ct.toDate() : null,
    );
  }
}
