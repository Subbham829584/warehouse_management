import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:warehouse_management/core/formatters.dart';
import 'package:warehouse_management/models/product.dart';
import 'package:warehouse_management/screens/product_details_page.dart';
import 'package:warehouse_management/utils/color_palette.dart';
import 'package:warehouse_management/widgets/stock_badge.dart';

class ProductCard extends StatelessWidget {
  final ProductItem? item;
  final Product? product;
  final String? docID;

  const ProductCard({
    super.key,
    this.item,
    this.product,
    this.docID,
  });

  @override
  Widget build(BuildContext context) {
    final p = item?.product ?? product ?? const Product();
    final id = item?.id ?? docID ?? '';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ProductDetailsPage(
                item: item ?? ProductItem(id: id, product: p),
                product: p,
                docID: id,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 80,
                  width: 80,
                  color: ColorPalette.geyser.withValues(alpha: 0.3),
                  child: (p.image.trim().isNotEmpty)
                      ? CachedNetworkImage(
                          imageUrl: p.image.trim(),
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => const Icon(
                            Icons.inventory_2_outlined,
                            color: ColorPalette.timberGreen,
                          ),
                        )
                      : const Icon(
                          Icons.inventory_2_outlined,
                          color: ColorPalette.timberGreen,
                          size: 32,
                        ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            p.name.isEmpty ? 'Unnamed Product' : p.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: ColorPalette.timberGreen,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        StockBadge(p),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (p.location.isNotEmpty)
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 13,
                            color: ColorPalette.timberGreen.withValues(alpha: 0.6),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              p.location,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: ColorPalette.timberGreen.withValues(alpha: 0.65),
                              ),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (p.group.isNotEmpty)
                          Text(
                            p.group,
                            style: TextStyle(
                              fontSize: 12,
                              color: ColorPalette.timberGreen.withValues(alpha: 0.55),
                            ),
                          ),
                        if (p.group.isNotEmpty && p.company.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 5),
                            child: Icon(
                              Icons.circle,
                              size: 4,
                              color: ColorPalette.timberGreen.withValues(alpha: 0.4),
                            ),
                          ),
                        if (p.company.isNotEmpty)
                          Expanded(
                            child: Text(
                              p.company,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: ColorPalette.timberGreen.withValues(alpha: 0.55),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          Fmt.money(p.cost),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: ColorPalette.nileBlue,
                          ),
                        ),
                        Text(
                          '${p.quantity} ${p.unit}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: p.isOutOfStock
                                ? const Color(0xffe75757)
                                : p.isLowStock
                                    ? const Color(0xffe8a317)
                                    : ColorPalette.timberGreen,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
