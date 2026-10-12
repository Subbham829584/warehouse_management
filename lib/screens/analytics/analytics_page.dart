import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:warehouse_management/core/app_scope.dart';
import 'package:warehouse_management/core/ui.dart';
import 'package:warehouse_management/models/product.dart';
import 'package:flutter/services.dart';
import 'package:warehouse_management/utils/color_palette.dart';

enum AbcClass { a, b, c }

class AbcItem {
  const AbcItem({
    required this.item,
    required this.abcClass,
    required this.valueSharePct,
    required this.cumulativeValuePct,
    required this.daysOfSupply,
  });

  final ProductItem item;
  final AbcClass abcClass;
  final double valueSharePct;
  final double cumulativeValuePct;
  final int daysOfSupply;
}

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  AbcClass? _filterClass;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final scope = AppScope.of(context);

    return Scaffold(
      backgroundColor: ColorPalette.aquaHaze,
      appBar: AppBar(
        title: const Text('ABC Analytics & Forecasting'),
        actions: [
          IconButton(
            tooltip: 'Export ABC Report',
            icon: const Icon(Icons.file_download_outlined),
            onPressed: () => _exportAbcReport(context, scope),
          ),
        ],
      ),
      body: StreamBuilder<List<ProductItem>>(
        stream: scope.repo.watchProducts(),
        builder: (ctx, snap) {
          final products = snap.data ?? [];
          if (products.isEmpty) {
            return const Center(
              child: Text('No inventory data available for analysis.'),
            );
          }

          final abcAnalysis = _computeAbc(products);
          final totalValuation =
              products.fold(0.0, (acc, p) => acc + p.product.totalValue);

          final classA =
              abcAnalysis.where((i) => i.abcClass == AbcClass.a).toList();
          final classB =
              abcAnalysis.where((i) => i.abcClass == AbcClass.b).toList();
          final classC =
              abcAnalysis.where((i) => i.abcClass == AbcClass.c).toList();

          final aVal = classA.fold(0.0, (acc, i) => acc + i.item.product.totalValue);
          final bVal = classB.fold(0.0, (acc, i) => acc + i.item.product.totalValue);
          final cVal = classC.fold(0.0, (acc, i) => acc + i.item.product.totalValue);

          final reorderRiskItems =
              abcAnalysis.where((i) => i.daysOfSupply <= 7).toList();

          var displayedItems = abcAnalysis;
          if (_filterClass != null) {
            displayedItems =
                abcAnalysis.where((i) => i.abcClass == _filterClass).toList();
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Total Valuation Banner
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [ColorPalette.timberGreen, ColorPalette.nileBlue],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'TOTAL WAREHOUSE CAPITAL',
                          style: TextStyle(
                            fontSize: 11,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.bold,
                            color: Colors.white70,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${products.length} Active SKUs',
                            style: const TextStyle(
                                fontSize: 11, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      currency.format(totalValuation),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Value distribution bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Row(
                        children: [
                          Expanded(
                            flex: (aVal / (totalValuation == 0 ? 1 : totalValuation) * 100).round().clamp(1, 100),
                            child: Container(height: 8, color: Colors.amber),
                          ),
                          Expanded(
                            flex: (bVal / (totalValuation == 0 ? 1 : totalValuation) * 100).round().clamp(1, 100),
                            child: Container(height: 8, color: Colors.blue),
                          ),
                          Expanded(
                            flex: (cVal / (totalValuation == 0 ? 1 : totalValuation) * 100).round().clamp(1, 100),
                            child: Container(height: 8, color: Colors.teal),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildLegend('Class A (80%)', Colors.amber),
                        _buildLegend('Class B (15%)', Colors.blue),
                        _buildLegend('Class C (5%)', Colors.teal),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // ABC Class Summary Cards
              Row(
                children: [
                  _buildAbcCard(
                    title: 'Class A (Critical)',
                    count: classA.length,
                    valueStr: currency.format(aVal),
                    color: Colors.amber.shade800,
                    selected: _filterClass == AbcClass.a,
                    onTap: () => setState(() => _filterClass =
                        _filterClass == AbcClass.a ? null : AbcClass.a),
                  ),
                  const SizedBox(width: 8),
                  _buildAbcCard(
                    title: 'Class B (Medium)',
                    count: classB.length,
                    valueStr: currency.format(bVal),
                    color: Colors.blue.shade700,
                    selected: _filterClass == AbcClass.b,
                    onTap: () => setState(() => _filterClass =
                        _filterClass == AbcClass.b ? null : AbcClass.b),
                  ),
                  const SizedBox(width: 8),
                  _buildAbcCard(
                    title: 'Class C (Bulk/Low)',
                    count: classC.length,
                    valueStr: currency.format(cVal),
                    color: Colors.teal.shade700,
                    selected: _filterClass == AbcClass.c,
                    onTap: () => setState(() => _filterClass =
                        _filterClass == AbcClass.c ? null : AbcClass.c),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Reorder Risk Alert Box
              if (reorderRiskItems.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.crisis_alert,
                          color: Colors.red.shade700, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${reorderRiskItems.length} SKUs at Critical Stockout Risk',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Colors.red.shade900,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Estimated days of supply is 7 days or less based on current consumption velocity.',
                              style: TextStyle(
                                  fontSize: 11, color: Colors.red.shade800),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              // Item Breakdown Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _filterClass == null
                        ? 'SKU Classification & Forecast Velocity'
                        : 'Class ${_filterClass.toString().split('.').last.toUpperCase()} SKUs',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: ColorPalette.timberGreen,
                    ),
                  ),
                  if (_filterClass != null)
                    TextButton(
                      onPressed: () => setState(() => _filterClass = null),
                      child: const Text('Show All'),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              // Item Cards
              ...displayedItems.map((item) => _buildAbcItemTile(item, currency)),
              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLegend(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildAbcCard({
    required String title,
    required int count,
    required String valueStr,
    required Color color,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.12) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? color : Colors.grey.shade200,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Text(
                '$count SKUs',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: ColorPalette.timberGreen,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                valueStr,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAbcItemTile(AbcItem abc, NumberFormat currency) {
    Color classColor;
    String classLabel;
    switch (abc.abcClass) {
      case AbcClass.a:
        classColor = Colors.amber.shade800;
        classLabel = 'Class A';
        break;
      case AbcClass.b:
        classColor = Colors.blue.shade700;
        classLabel = 'Class B';
        break;
      case AbcClass.c:
        classColor = Colors.teal.shade700;
        classLabel = 'Class C';
        break;
    }

    final isLowSupply = abc.daysOfSupply <= 7;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: classColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                classLabel,
                style: TextStyle(
                  color: classColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    abc.item.product.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: ColorPalette.timberGreen,
                    ),
                  ),
                  Text(
                    '${abc.item.product.group} • Qty: ${abc.item.product.quantity} @ \$${abc.item.product.cost.toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        isLowSupply
                            ? Icons.warning_amber_rounded
                            : Icons.check_circle_outline,
                        size: 13,
                        color: isLowSupply ? Colors.red : Colors.green,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Est. Supply: ${abc.daysOfSupply} days remaining',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isLowSupply
                              ? Colors.red.shade800
                              : Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  currency.format(abc.item.product.totalValue),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: ColorPalette.timberGreen,
                  ),
                ),
                Text(
                  '${abc.valueSharePct.toStringAsFixed(1)}% of capital',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<AbcItem> _computeAbc(List<ProductItem> list) {
    if (list.isEmpty) return [];

    // Sort by descending total valuation
    final sorted = List<ProductItem>.from(list)
      ..sort((a, b) => b.product.totalValue.compareTo(a.product.totalValue));

    final totalVal = sorted.fold(0.0, (acc, p) => acc + p.product.totalValue);
    double cumulative = 0.0;
    final results = <AbcItem>[];

    for (final p in sorted) {
      final itemVal = p.product.totalValue;
      final sharePct = totalVal == 0 ? 0.0 : (itemVal / totalVal) * 100;
      cumulative += sharePct;

      AbcClass c;
      if (cumulative <= 80.0 || results.isEmpty) {
        c = AbcClass.a;
      } else if (cumulative <= 95.0) {
        c = AbcClass.b;
      } else {
        c = AbcClass.c;
      }

      // Model days of supply: quantity divided by estimated velocity (1.5 - 4 per day)
      final dailyDemand = (p.product.quantity > 50 ? 4 : (p.product.quantity > 20 ? 2 : 1));
      final days = (p.product.quantity / dailyDemand).round();

      results.add(AbcItem(
        item: p,
        abcClass: c,
        valueSharePct: sharePct,
        cumulativeValuePct: cumulative,
        daysOfSupply: days,
      ));
    }

    return results;
  }

  void _exportAbcReport(BuildContext context, AppScope scope) async {
    final stream = scope.repo.watchProducts();
    final products = await stream.first;
    if (products.isEmpty) {
      if (context.mounted) showMessage(context, 'No products to export.');
      return;
    }

    final abc = _computeAbc(products);
    final header = [
      'SKU',
      'Name',
      'Group',
      'Quantity',
      'Cost',
      'Total Value',
      'ABC Classification',
      'Capital Share %',
      'Days of Supply',
    ];

    final rows = abc.map((a) {
      return [
        a.item.product.sku,
        a.item.product.name,
        a.item.product.group,
        '${a.item.product.quantity}',
        a.item.product.cost.toStringAsFixed(2),
        a.item.product.totalValue.toStringAsFixed(2),
        a.abcClass.toString().split('.').last.toUpperCase(),
        a.valueSharePct.toStringAsFixed(1),
        '${a.daysOfSupply}',
      ];
    }).toList();

    final buffer = StringBuffer()..writeln(header.join(','));
    for (final r in rows) {
      buffer.writeln(r.map((c) => c.contains(',') ? '"$c"' : c).join(','));
    }
    await Clipboard.setData(ClipboardData(text: buffer.toString()));
    if (context.mounted) {
      showMessage(context, 'ABC Analytics report copied to clipboard as CSV!');
    }
  }
}
