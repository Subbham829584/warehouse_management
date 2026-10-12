import 'package:cloud_firestore/cloud_firestore.dart';

enum MovementType { stockIn, stockOut, adjustment }

extension MovementTypeX on MovementType {
  String get label => switch (this) {
        MovementType.stockIn => 'Stock In',
        MovementType.stockOut => 'Stock Out',
        MovementType.adjustment => 'Adjustment',
      };

  String get key => name;

  static MovementType parse(String? s) => MovementType.values
      .firstWhere((e) => e.name == s, orElse: () => MovementType.adjustment);
}

/// Immutable audit-trail entry. Every quantity change creates one.
class StockMovement {
  const StockMovement({
    required this.id,
    required this.productId,
    required this.productName,
    required this.type,
    required this.change,
    required this.quantityAfter,
    required this.userEmail,
    this.note = '',
    this.createdAt,
  });

  final String id;
  final String productId;
  final String productName;
  final MovementType type;

  /// Signed delta: +20 for stock-in, -5 for stock-out.
  final int change;
  final int quantityAfter;
  final String userEmail;
  final String note;
  final DateTime? createdAt;

  factory StockMovement.fromMap(String id, Map<String, dynamic> m) {
    final ts = m['createdAt'];
    return StockMovement(
      id: id,
      productId: (m['productId'] as String?) ?? '',
      productName: (m['productName'] as String?) ?? '',
      type: MovementTypeX.parse(m['type'] as String?),
      change: (m['change'] as num?)?.toInt() ?? 0,
      quantityAfter: (m['quantityAfter'] as num?)?.toInt() ?? 0,
      userEmail: (m['userEmail'] as String?) ?? '',
      note: (m['note'] as String?) ?? '',
      createdAt: ts is Timestamp ? ts.toDate() : null,
    );
  }

  Map<String, dynamic> toMap() => {
        'productId': productId,
        'productName': productName,
        'type': type.key,
        'change': change,
        'quantityAfter': quantityAfter,
        'userEmail': userEmail,
        'note': note,
        'createdAt': FieldValue.serverTimestamp(),
      };
}
