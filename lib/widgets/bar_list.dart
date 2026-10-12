import 'package:flutter/material.dart';
import 'package:warehouse_management/utils/color_palette.dart';

/// Dependency-free horizontal bar chart: label, bar, value text.
class BarList extends StatelessWidget {
  const BarList({super.key, required this.data, required this.format});
  final Map<String, double> data;
  final String Function(double) format;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox();
    final entries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final max = entries.first.value <= 0 ? 1.0 : entries.first.value;
    return Column(
      children: [
        for (final e in entries)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(children: [
              SizedBox(
                width: 110,
                child: Text(e.key,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12)),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: (e.value / max).clamp(0.0, 1.0),
                    minHeight: 10,
                    backgroundColor: ColorPalette.geyser,
                    color: ColorPalette.pacificBlue,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 76,
                child: Text(format(e.value),
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ]),
          ),
      ],
    );
  }
}
