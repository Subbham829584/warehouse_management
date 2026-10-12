import 'package:flutter/material.dart';
import 'package:warehouse_management/core/app_scope.dart';
import 'package:warehouse_management/core/ui.dart';
import 'package:warehouse_management/models/product.dart';
import 'package:warehouse_management/widgets/empty_state.dart';
import 'package:warehouse_management/widgets/product_group_card.dart';

class GroupsPage extends StatelessWidget {
  const GroupsPage({super.key});

  Future<void> _addGroup(BuildContext context) async {
    final repo = AppScope.of(context).repo;
    final ctrl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add product group'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: 'e.g. Electronics'),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text),
              child: const Text('Add')),
        ],
      ),
    );
    ctrl.dispose();
    if (name == null || name.trim().isEmpty) return;
    try {
      final ok = await repo.addGroup(name);
      if (context.mounted) {
        showMessage(context, ok ? 'Group added' : 'That group already exists',
            error: !ok);
      }
    } catch (e) {
      if (context.mounted) showMessage(context, 'Failed: $e', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = AppScope.of(context).repo;
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addGroup(context),
        icon: const Icon(Icons.add),
        label: const Text('Group'),
      ),
      body: StreamBuilder<List<String>>(
        stream: repo.watchGroups(),
        builder: (context, gSnap) {
          if (gSnap.hasError) return ErrorState(gSnap.error);
          if (!gSnap.hasData)
            return const Center(child: CircularProgressIndicator());
          final groups = gSnap.data!;
          if (groups.isEmpty) {
            return const EmptyState(
                icon: Icons.folder_open,
                title: 'No product groups',
                subtitle: 'Tap "+ Group" to create one.');
          }
          return StreamBuilder<List<ProductItem>>(
            stream: repo.watchProducts(),
            builder: (context, pSnap) {
              final all = pSnap.data ?? const <ProductItem>[];
              final w = MediaQuery.of(context).size.width;
              final cols = w > 1200
                  ? 4
                  : w > 750
                      ? 3
                      : 2;
              return GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cols,
                  childAspectRatio: w > 1200 ? 2.0 : w > 750 ? 1.6 : 1.32,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: groups.length,
                itemBuilder: (_, i) {
                  final inGroup =
                      all.where((p) => p.product.group == groups[i]).toList();
                  final val = inGroup.fold<double>(
                      0.0, (acc, item) => acc + item.product.totalValue);
                  return ProductGroupCard(
                    key: ValueKey(groups[i]),
                    name: groups[i],
                    count: pSnap.hasData ? inGroup.length : null,
                    totalValue: pSnap.hasData ? val : null,
                    lowCount: inGroup
                        .where((p) =>
                            p.product.isLowStock || p.product.isOutOfStock)
                        .length,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
