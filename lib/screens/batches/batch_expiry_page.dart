import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:warehouse_management/core/ui.dart';
import 'package:warehouse_management/models/batch_lot.dart';
import 'package:warehouse_management/services/enterprise_store.dart';
import 'package:warehouse_management/utils/color_palette.dart';

class BatchExpiryPage extends StatefulWidget {
  const BatchExpiryPage({super.key});

  @override
  State<BatchExpiryPage> createState() => _BatchExpiryPageState();
}

class _BatchExpiryPageState extends State<BatchExpiryPage> {
  final _store = EnterpriseStore.instance;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _store.addListener(_onUpdate);
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _store.removeListener(_onUpdate);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allLots = _store.batchLots;
    final expiredCount = allLots.where((b) => b.isExpired).length;
    final nearExpiryCount =
        allLots.where((b) => b.isNearExpiry && !b.isExpired).length;
    final activeCount =
        allLots.where((b) => !b.isExpired && !b.isNearExpiry).length;

    var filtered = allLots;
    if (_filter == 'nearExpiry') {
      filtered = allLots.where((b) => b.isNearExpiry && !b.isExpired).toList();
    } else if (_filter == 'expired') {
      filtered = allLots.where((b) => b.isExpired).toList();
    } else if (_filter == 'active') {
      filtered =
          allLots.where((b) => !b.isExpired && !b.isNearExpiry).toList();
    }

    // Sort by FEFO (First-Expired-First-Out)
    final fefoSorted = List<BatchLot>.from(filtered)
      ..sort((a, b) => a.expiryDate.compareTo(b.expiryDate));

    return Scaffold(
      backgroundColor: ColorPalette.aquaHaze,
      appBar: AppBar(
        title: const Text('Batch & Expiry (FEFO Tracker)'),
      ),
      body: Column(
        children: [
          // FEFO Priority Metric Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: Row(
              children: [
                _buildKpi(
                  'FEFO Urgent (<45d)',
                  '$nearExpiryCount',
                  Icons.timelapse,
                  Colors.orange.shade800,
                ),
                const SizedBox(width: 8),
                _buildKpi(
                  'Expired Lots',
                  '$expiredCount',
                  Icons.report_problem_outlined,
                  Colors.red.shade700,
                ),
                const SizedBox(width: 8),
                _buildKpi(
                  'Active / Stable',
                  '$activeCount',
                  Icons.verified_outlined,
                  Colors.green.shade700,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Filter Tabs
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterPill('All Batches (${allLots.length})', 'all'),
                  const SizedBox(width: 8),
                  _buildFilterPill('FEFO Priority (<45d)', 'nearExpiry'),
                  const SizedBox(width: 8),
                  _buildFilterPill('Expired Lots', 'expired'),
                  const SizedBox(width: 8),
                  _buildFilterPill('Stable Shelf-Life', 'active'),
                ],
              ),
            ),
          ),
          // Batch List
          Expanded(
            child: fefoSorted.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: Text('No batches found matching this filter.',
                          style: TextStyle(color: Colors.grey)),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: fefoSorted.length,
                    itemBuilder: (ctx, i) =>
                        _buildBatchCard(context, fefoSorted[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpi(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterPill(String label, String key) {
    final selected = _filter == key;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: ColorPalette.pacificBlue.withValues(alpha: 0.2),
      onSelected: (_) => setState(() => _filter = key),
    );
  }

  Widget _buildBatchCard(BuildContext context, BatchLot lot) {
    final days = lot.daysUntilExpiry;
    Color statusColor;
    String statusBadge;
    if (lot.status == BatchStatus.quarantined) {
      statusColor = Colors.purple;
      statusBadge = 'QUARANTINED';
    } else if (lot.isExpired) {
      statusColor = Colors.red;
      statusBadge = 'EXPIRED';
    } else if (lot.isNearExpiry) {
      statusColor = Colors.orange;
      statusBadge = 'FEFO DISPATCH (FIRST)';
    } else {
      statusColor = Colors.green;
      statusBadge = 'HEALTHY';
    }

    final dateFormat = DateFormat('MMM d, yyyy');
    final progress = lot.initialQuantity == 0
        ? 0.0
        : (lot.remainingQuantity / lot.initialQuantity).clamp(0.0, 1.0);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: ColorPalette.pacificBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.qr_code,
                      color: ColorPalette.pacificBlue, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lot.batchNumber,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: ColorPalette.timberGreen,
                        ),
                      ),
                      Text(
                        '${lot.productName} • SKU: ${lot.sku}',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    statusBadge,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: ColorPalette.aquaHaze,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Bin Location',
                          style: TextStyle(
                              fontSize: 10, color: Colors.grey.shade600)),
                      Text(lot.storageLocation,
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Mfg Date',
                          style: TextStyle(
                              fontSize: 10, color: Colors.grey.shade600)),
                      Text(dateFormat.format(lot.manufacturingDate),
                          style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Expiry Date',
                          style: TextStyle(
                              fontSize: 10, color: Colors.grey.shade600)),
                      Text(
                        dateFormat.format(lot.expiryDate),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: lot.isExpired ? Colors.red : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  days <= 0
                      ? 'Expired ${days.abs()} days ago'
                      : '$days days shelf life remaining',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: days <= 0
                        ? Colors.red
                        : days <= 45
                            ? Colors.orange.shade800
                            : Colors.green.shade800,
                  ),
                ),
                Text(
                  '${lot.remainingQuantity} / ${lot.initialQuantity} units left',
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: Colors.grey.shade200,
                color: ColorPalette.pacificBlue,
              ),
            ),
            if (lot.isExpired && lot.status != BatchStatus.quarantined) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    _store.quarantineBatch(lot.id);
                    showMessage(context,
                        'Batch ${lot.batchNumber} moved to quarantine!');
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.block, size: 16),
                  label: const Text('Quarantine Expired Lot'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
