import 'package:flutter/material.dart';
import 'package:warehouse_management/core/formatters.dart';
import 'package:warehouse_management/screens/product_group_page.dart';
import 'package:warehouse_management/utils/color_palette.dart';

class ProductGroupCard extends StatelessWidget {
  final String? name;
  final int? count;
  final int? lowCount;
  final double? totalValue;

  const ProductGroupCard({
    super.key,
    this.name,
    this.count,
    this.lowCount,
    this.totalValue,
  });

  @override
  Widget build(BuildContext context) {
    final groupName = name ?? '';
    final hasAlert = (lowCount != null && lowCount! > 0);

    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: hasAlert
              ? const Color(0xffe8a317).withValues(alpha: 0.3)
              : Colors.black.withValues(alpha: 0.05),
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ProductGroupPage(name: groupName),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          ColorPalette.pacificBlue.withValues(alpha: 0.2),
                          ColorPalette.pacificBlue.withValues(alpha: 0.08),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.folder_open_rounded,
                      color: ColorPalette.pacificBlue,
                      size: 22,
                    ),
                  ),
                  const Spacer(),
                  if (hasAlert)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xffe8a317).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.warning_amber_rounded,
                              size: 12, color: Color(0xffe8a317)),
                          const SizedBox(width: 3),
                          Text(
                            '$lowCount',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xffe8a317),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const Spacer(),
              Text(
                groupName,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: ColorPalette.timberGreen,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    count != null ? '$count items' : 'View products',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: ColorPalette.timberGreen.withValues(alpha: 0.6),
                    ),
                  ),
                  if (totalValue != null && totalValue! > 0)
                    Text(
                      Fmt.moneyCompact(totalValue),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff2e9e6b),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
