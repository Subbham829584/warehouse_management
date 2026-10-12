import 'package:flutter/material.dart';
import 'package:warehouse_management/models/product.dart';

class StockBadge extends StatelessWidget {
  const StockBadge(this.product, {super.key});
  final Product product;

  @override
  Widget build(BuildContext context) {
    final String label;
    final Color color;
    if (product.isOutOfStock) {
      label = 'Out of stock';
      color = const Color(0xffe75757);
    } else if (product.isLowStock) {
      label = 'Low stock';
      color = const Color(0xffe8a317);
    } else {
      label = 'In stock';
      color = const Color(0xff2e9e6b);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
