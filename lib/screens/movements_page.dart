import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:warehouse_management/core/app_scope.dart';
import 'package:warehouse_management/core/ui.dart';
import 'package:warehouse_management/models/stock_movement.dart';
import 'package:warehouse_management/screens/product_details_page.dart';
import 'package:warehouse_management/services/export_service.dart';
import 'package:warehouse_management/widgets/empty_state.dart';

/// Global audit trail of every stock change.
class MovementsPage extends StatelessWidget {
  const MovementsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = AppScope.of(context).repo;
    return StreamBuilder<List<StockMovement>>(
      stream: repo.watchMovements(limit: 200),
      builder: (context, snap) {
        if (snap.hasError) return ErrorState(snap.error);
        if (!snap.hasData)
          return const Center(child: CircularProgressIndicator());
        final list = snap.data!;
        if (list.isEmpty) {
          return const EmptyState(
              icon: Icons.history,
              title: 'No activity yet',
              subtitle: 'Stock in/out and counts will be logged here.');
        }
        return Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                icon: const Icon(Icons.copy, size: 16),
                label: const Text('Copy CSV'),
                onPressed: () async {
                  await Clipboard.setData(
                      ClipboardData(text: ExportService.movementsCsv(list)));
                  if (context.mounted)
                    showMessage(context, 'Activity log copied');
                },
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: list.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) => MovementTile(list[i]),
            ),
          ),
        ]);
      },
    );
  }
}
