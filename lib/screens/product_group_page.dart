import 'package:flutter/material.dart';
import 'package:warehouse_management/core/app_scope.dart';
import 'package:warehouse_management/core/ui.dart';
import 'package:warehouse_management/models/product.dart';
import 'package:warehouse_management/screens/product_form_page.dart';
import 'package:warehouse_management/screens/search_page.dart';
import 'package:warehouse_management/widgets/empty_state.dart';
import 'package:warehouse_management/widgets/product_card.dart';

class ProductGroupPage extends StatelessWidget {
  final String? name;
  const ProductGroupPage({super.key, this.name});

  Future<void> _deleteGroup(BuildContext context, String groupName) async {
    final ok = await confirm(
      context,
      title: 'Delete group?',
      message: 'Are you sure you want to delete "$groupName"?',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!ok) return;
    if (!context.mounted) return;

    final repo = AppScope.of(context).repo;
    try {
      await repo.deleteGroup(groupName);
      if (context.mounted) {
        showMessage(context, 'Group "$groupName" deleted');
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (context.mounted) {
        showMessage(context, '$e'.replaceFirst('Bad state: ', ''), error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupName = name ?? '';
    final repo = AppScope.of(context).repo;

    return Scaffold(
      appBar: AppBar(
        title: Text(groupName.isEmpty ? 'Group' : groupName),
        actions: [
          IconButton(
            tooltip: 'Search in group',
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => SearchPage(group: groupName),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Delete group',
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _deleteGroup(context, groupName),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProductFormPage(group: groupName),
          ),
        ),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<ProductItem>>(
        stream: repo.watchProducts(group: groupName),
        builder: (context, snap) {
          if (snap.hasError) return ErrorState(snap.error);
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snap.data!;
          if (items.isEmpty) {
            return EmptyState(
              icon: Icons.inventory_2_outlined,
              title: 'No products in "$groupName"',
              subtitle: 'Tap the + button below to add your first product.',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: items.length,
            itemBuilder: (_, i) => ProductCard(item: items[i]),
          );
        },
      ),
    );
  }
}
