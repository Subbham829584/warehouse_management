import 'package:flutter/material.dart';
import 'package:warehouse_management/screens/product_group_page.dart';
import 'package:warehouse_management/utils/color_palette.dart';

class ProductGroupCard extends StatelessWidget {
  final String? name;
  final int? count;
  final int? lowCount;

  const ProductGroupCard({
    super.key,
    this.name,
    this.count,
    this.lowCount,
  });

  @override
  Widget build(BuildContext context) {
    final groupName = name ?? '';
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: ColorPalette.pacificBlue.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.folder_outlined,
                      color: ColorPalette.pacificBlue,
                      size: 20,
                    ),
                  ),
                  const Spacer(),
                  if (lowCount != null && lowCount! > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xffe8a317).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$lowCount alert',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xffe8a317),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
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
              Text(
                count != null ? '$count items' : 'View products',
                style: TextStyle(
                  fontSize: 12,
                  color: ColorPalette.timberGreen.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
