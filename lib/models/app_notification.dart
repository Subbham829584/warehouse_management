import 'package:cloud_firestore/cloud_firestore.dart';

enum NotifType { lowStock, expiryAlert, pendingPO, pendingReturn, cycleCountDue, reorderSuggestion }

extension NotifTypeX on NotifType {
  String get label => switch (this) {
        NotifType.lowStock => 'Low Stock',
        NotifType.expiryAlert => 'Expiry Alert',
        NotifType.pendingPO => 'Pending PO',
        NotifType.pendingReturn => 'Pending Return',
        NotifType.cycleCountDue => 'Cycle Count Due',
        NotifType.reorderSuggestion => 'Reorder Suggested',
      };
  String get key => name;
  static NotifType parse(String? s) => NotifType.values
      .firstWhere((e) => e.name == s, orElse: () => NotifType.lowStock);
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    this.isRead = false,
    this.referenceId = '',
  });

  final String id;
  final NotifType type;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool isRead;
  final String referenceId;

  AppNotification markRead() => AppNotification(
        id: id,
        type: type,
        title: title,
        body: body,
        createdAt: createdAt,
        isRead: true,
        referenceId: referenceId,
      );

  Map<String, dynamic> toMap() => {
        'type': type.key,
        'title': title,
        'body': body,
        'createdAt': Timestamp.fromDate(createdAt),
        'isRead': isRead,
        'referenceId': referenceId,
      };

  factory AppNotification.fromMap(String id, Map<String, dynamic> m) {
    final ts = m['createdAt'];
    return AppNotification(
      id: id,
      type: NotifTypeX.parse(m['type'] as String?),
      title: (m['title'] as String?) ?? '',
      body: (m['body'] as String?) ?? '',
      createdAt: ts is Timestamp ? ts.toDate() : DateTime.now(),
      isRead: (m['isRead'] as bool?) ?? false,
      referenceId: (m['referenceId'] as String?) ?? '',
    );
  }
}
