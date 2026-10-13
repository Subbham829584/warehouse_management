import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:warehouse_management/models/app_notification.dart';
import 'package:warehouse_management/services/wms_service.dart';
import 'package:warehouse_management/utils/color_palette.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  NotifType? _selectedType;

  @override
  Widget build(BuildContext context) {
    final wms = WmsService.instance;

    return ListenableBuilder(
      listenable: wms,
      builder: (context, _) {
        final allNotifs = wms.notifications;
        final filtered = _selectedType == null
            ? allNotifs
            : allNotifs.where((n) => n.type == _selectedType).toList();

        return Scaffold(
          appBar: AppBar(
            title: const Text('Warehouse Alerts'),
            actions: [
              TextButton(
                onPressed: () => wms.markAllRead(),
                child: const Text('Mark all read', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
          body: Column(
            children: [
              // Filter chips
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        selected: _selectedType == null,
                        label: Text('All (${allNotifs.length})'),
                        onSelected: (_) => setState(() => _selectedType = null),
                      ),
                      const SizedBox(width: 8),
                      for (final type in NotifType.values)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            selected: _selectedType == type,
                            label: Text(type.label),
                            onSelected: (sel) => setState(() => _selectedType = sel ? type : null),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1),

              // Notification List
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.notifications_off_outlined, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text('No alerts in this category', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        itemBuilder: (ctx, i) {
                          final n = filtered[i];
                          final (icon, color) = _getMeta(n.type);

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: n.isRead ? 0 : 2,
                            color: n.isRead ? Colors.grey.shade50 : Colors.white,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () => wms.markNotificationRead(n.id),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor: color.withValues(alpha: 0.12),
                                      child: Icon(icon, color: color, size: 20),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: color.withValues(alpha: 0.1),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  n.type.label,
                                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
                                                ),
                                              ),
                                              Text(
                                                DateFormat('dd MMM, hh:mm a').format(n.createdAt),
                                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            n.title,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: n.isRead ? FontWeight.w600 : FontWeight.bold,
                                              color: n.isRead ? Colors.grey.shade800 : Colors.black,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            n.body,
                                            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (!n.isRead)
                                      Container(
                                        margin: const EdgeInsets.only(left: 8, top: 4),
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  (IconData, Color) _getMeta(NotifType type) => switch (type) {
    NotifType.lowStock => (Icons.warning_amber_rounded, Colors.orange),
    NotifType.expiryAlert => (Icons.event_busy, Colors.red),
    NotifType.pendingPO => (Icons.local_shipping, Colors.blue),
    NotifType.pendingReturn => (Icons.assignment_return, Colors.purple),
    NotifType.cycleCountDue => (Icons.fact_check, Colors.teal),
    NotifType.reorderSuggestion => (Icons.add_shopping_cart, ColorPalette.nileBlue),
  };
}
