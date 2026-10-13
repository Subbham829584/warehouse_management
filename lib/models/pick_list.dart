import 'package:cloud_firestore/cloud_firestore.dart';

enum PickStatus { pending, inProgress, completed, cancelled }

extension PickStatusX on PickStatus {
  String get label => switch (this) {
        PickStatus.pending => 'Pending',
        PickStatus.inProgress => 'In Progress',
        PickStatus.completed => 'Completed',
        PickStatus.cancelled => 'Cancelled',
      };
  String get key => name;
  static PickStatus parse(String? s) => PickStatus.values
      .firstWhere((e) => e.name == s, orElse: () => PickStatus.pending);
}

class PickLineItem {
  const PickLineItem({
    required this.productId,
    required this.productName,
    required this.sku,
    required this.zone,
    required this.binCode,
    required this.qtyRequired,
    this.qtyPicked = 0,
    this.isPicked = false,
    this.lotNumber = '',
  });

  final String productId;
  final String productName;
  final String sku;
  final String zone;
  final String binCode; // sorted by bin for efficient picking
  final int qtyRequired;
  final int qtyPicked;
  final bool isPicked;
  final String lotNumber;

  PickLineItem copyWith({int? qtyPicked, bool? isPicked}) => PickLineItem(
        productId: productId,
        productName: productName,
        sku: sku,
        zone: zone,
        binCode: binCode,
        qtyRequired: qtyRequired,
        qtyPicked: qtyPicked ?? this.qtyPicked,
        isPicked: isPicked ?? this.isPicked,
        lotNumber: lotNumber,
      );

  Map<String, dynamic> toMap() => {
        'productId': productId,
        'productName': productName,
        'sku': sku,
        'zone': zone,
        'binCode': binCode,
        'qtyRequired': qtyRequired,
        'qtyPicked': qtyPicked,
        'isPicked': isPicked,
        'lotNumber': lotNumber,
      };

  factory PickLineItem.fromMap(Map<String, dynamic> m) => PickLineItem(
        productId: (m['productId'] as String?) ?? '',
        productName: (m['productName'] as String?) ?? '',
        sku: (m['sku'] as String?) ?? '',
        zone: (m['zone'] as String?) ?? '',
        binCode: (m['binCode'] as String?) ?? '',
        qtyRequired: (m['qtyRequired'] as num?)?.toInt() ?? 0,
        qtyPicked: (m['qtyPicked'] as num?)?.toInt() ?? 0,
        isPicked: (m['isPicked'] as bool?) ?? false,
        lotNumber: (m['lotNumber'] as String?) ?? '',
      );
}

/// A zone-sorted pick list - supports wave, batch, and zone methods.
class PickList {
  const PickList({
    required this.id,
    required this.pickNumber,
    required this.orderId,
    required this.customerName,
    required this.assignedTo,
    required this.createdAt,
    this.status = PickStatus.pending,
    this.filterZone = '', // empty = all zones
    this.items = const [],
    this.completedAt,
    this.notes = '',
  });

  final String id;
  final String pickNumber;
  final String orderId;
  final String customerName;
  final String assignedTo;
  final DateTime createdAt;
  final PickStatus status;
  final String filterZone;
  final List<PickLineItem> items;
  final DateTime? completedAt;
  final String notes;

  int get totalLines => items.length;
  int get pickedLines => items.where((i) => i.isPicked).length;
  bool get isComplete => totalLines > 0 && pickedLines == totalLines;

  /// Returns items sorted by bin code for efficient pick walk.
  List<PickLineItem> get sortedByBin =>
      List.of(items)..sort((a, b) => a.binCode.compareTo(b.binCode));

  PickList copyWith({
    PickStatus? status,
    List<PickLineItem>? items,
    DateTime? completedAt,
    String? notes,
  }) =>
      PickList(
        id: id,
        pickNumber: pickNumber,
        orderId: orderId,
        customerName: customerName,
        assignedTo: assignedTo,
        createdAt: createdAt,
        status: status ?? this.status,
        filterZone: filterZone,
        items: items ?? this.items,
        completedAt: completedAt ?? this.completedAt,
        notes: notes ?? this.notes,
      );

  Map<String, dynamic> toMap() => {
        'pickNumber': pickNumber,
        'orderId': orderId,
        'customerName': customerName,
        'assignedTo': assignedTo,
        'createdAt': Timestamp.fromDate(createdAt),
        'status': status.key,
        'filterZone': filterZone,
        'items': items.map((i) => i.toMap()).toList(),
        'completedAt':
            completedAt != null ? Timestamp.fromDate(completedAt!) : null,
        'notes': notes,
      };

  factory PickList.fromMap(String id, Map<String, dynamic> m) {
    final ca = m['createdAt'];
    final cp = m['completedAt'];
    return PickList(
      id: id,
      pickNumber: (m['pickNumber'] as String?) ?? '',
      orderId: (m['orderId'] as String?) ?? '',
      customerName: (m['customerName'] as String?) ?? '',
      assignedTo: (m['assignedTo'] as String?) ?? '',
      createdAt: ca is Timestamp ? ca.toDate() : DateTime.now(),
      status: PickStatusX.parse(m['status'] as String?),
      filterZone: (m['filterZone'] as String?) ?? '',
      items: ((m['items'] as List?) ?? [])
          .map((e) => PickLineItem.fromMap(e as Map<String, dynamic>))
          .toList(),
      completedAt: cp is Timestamp ? cp.toDate() : null,
      notes: (m['notes'] as String?) ?? '',
    );
  }
}
