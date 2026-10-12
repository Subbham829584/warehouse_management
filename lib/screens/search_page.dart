import 'dart:async';
import 'package:flutter/material.dart';
import 'package:warehouse_management/core/app_scope.dart';
import 'package:warehouse_management/models/product.dart';
import 'package:warehouse_management/widgets/empty_state.dart';
import 'package:warehouse_management/widgets/product_card.dart';

/// One search page for both global search and in-group search.
/// Matches name, company, SKU and barcode, case-insensitively.
class SearchPage extends StatefulWidget {
  const SearchPage({super.key, this.group});
  final String? group;

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _ctrl = TextEditingController();
  Timer? _debounce;
  String _query = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  void _onChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (mounted) setState(() => _query = v.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    final repo = AppScope.of(context).repo;
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _ctrl,
          autofocus: true,
          onChanged: _onChanged,
          textInputAction: TextInputAction.search,
          style: const TextStyle(fontSize: 18),
          decoration: InputDecoration(
            border: InputBorder.none,
            filled: false,
            hintText: widget.group == null
                ? 'Search all products…'
                : 'Search in ${widget.group}…',
          ),
        ),
        actions: [
          if (_query.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                _ctrl.clear();
                setState(() => _query = '');
              },
            ),
        ],
      ),
      body: _query.isEmpty
          ? const EmptyState(
              icon: Icons.search,
              title: 'Search by name, company, SKU or barcode')
          : StreamBuilder<List<ProductItem>>(
              stream: repo.searchProducts(_query, group: widget.group),
              builder: (context, snap) {
                if (snap.hasError) return ErrorState(snap.error);
                if (!snap.hasData)
                  return const Center(child: CircularProgressIndicator());
                final items = snap.data!;
                if (items.isEmpty) {
                  return EmptyState(
                      icon: Icons.search_off,
                      title: "No results for '$_query'");
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  itemBuilder: (_, i) => ProductCard(item: items[i]),
                );
              },
            ),
    );
  }
}
