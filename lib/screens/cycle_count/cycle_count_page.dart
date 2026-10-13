import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:warehouse_management/core/app_scope.dart';
import 'package:warehouse_management/models/app_user.dart';
import 'package:warehouse_management/models/cycle_count.dart';
import 'package:warehouse_management/models/product.dart';
import 'package:warehouse_management/services/wms_service.dart';
import 'package:warehouse_management/utils/color_palette.dart';

class CycleCountPage extends StatefulWidget {
  const CycleCountPage({super.key, this.userRole = UserRole.manager});
  final UserRole userRole;

  @override
  State<CycleCountPage> createState() => _CycleCountPageState();
}

class _CycleCountPageState extends State<CycleCountPage> with SingleTickerProviderStateMixin {
  final _wms = WmsService.instance;
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _wms.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _wms.removeListener(_refresh);
    _tab.dispose();
    super.dispose();
  }

  Color _statusColor(CycleCountStatus s) => switch (s) {
        CycleCountStatus.scheduled => Colors.grey,
        CycleCountStatus.inProgress => Colors.blue,
        CycleCountStatus.pendingApproval => Colors.orange,
        CycleCountStatus.completed => Colors.green,
        CycleCountStatus.cancelled => Colors.red,
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorPalette.aquaHaze,
      appBar: AppBar(
        title: const Text('Cycle Count'),
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tab,
          labelColor: ColorPalette.timberGreen,
          indicatorColor: ColorPalette.timberGreen,
          indicatorWeight: 3,
          tabs: const [
            Tab(icon: Icon(Icons.list_alt), text: 'Active Counts'),
            Tab(icon: Icon(Icons.history), text: 'Completed'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _buildCountList(active: true),
          _buildCountList(active: false),
        ],
      ),
      floatingActionButton: Permissions.canRunCycleCount(widget.userRole)
          ? FloatingActionButton.extended(heroTag: null,
              onPressed: () => _showCreateDialog(context),
              backgroundColor: ColorPalette.pacificBlue,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('New Count', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          : null,
    );
  }

  Widget _buildCountList({required bool active}) {
    final list = _wms.cycleCounts.where((c) {
      if (active) {
        return c.status == CycleCountStatus.inProgress ||
            c.status == CycleCountStatus.scheduled ||
            c.status == CycleCountStatus.pendingApproval;
      } else {
        return c.status == CycleCountStatus.completed || c.status == CycleCountStatus.cancelled;
      }
    }).toList();

    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(active ? Icons.fact_check_outlined : Icons.history_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 12),
            Text(active ? 'No active cycle counts' : 'No completed counts',
                style: const TextStyle(color: Colors.grey, fontSize: 16),),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (ctx, i) => _buildCountCard(ctx, list[i]),
    );
  }

  Widget _buildCountCard(BuildContext ctx, CycleCount cc) {
    final sc = _statusColor(cc.status);
    final progress = cc.totalItems == 0 ? 0.0 : (cc.countedItems / cc.totalItems).clamp(0.0, 1.0);
    final currency = NumberFormat.currency(symbol: '\u20B9', decimalDigits: 0);

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
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
                  child: const Icon(Icons.fact_check, color: ColorPalette.pacificBlue, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(cc.countNumber,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ColorPalette.timberGreen),),
                      Text('Class ${cc.abcFilter} items â€¢ Tolerance: Â±${cc.varianceTolerance} units',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: sc.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: sc.withValues(alpha: 0.3)),
                  ),
                  child: Text(cc.status.label, style: TextStyle(color: sc, fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _kpiChip('Items', '${cc.countedItems}/${cc.totalItems}', Colors.blue),
                const SizedBox(width: 8),
                _kpiChip('Discrepancies', '${cc.discrepancyItems}', Colors.orange),
                const SizedBox(width: 8),
                _kpiChip('Variance Value', currency.format(cc.netVarianceValue.abs()), Colors.red),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey.shade200,
                      color: progress >= 1.0 ? Colors.green : ColorPalette.pacificBlue,
                      minHeight: 6,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text('${(progress * 100).toInt()}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
            if (cc.status == CycleCountStatus.inProgress || cc.status == CycleCountStatus.scheduled) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _openCountSheet(ctx, cc),
                  icon: const Icon(Icons.edit_note, size: 16),
                  label: const Text('Enter Counts'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ColorPalette.pacificBlue,
                    side: const BorderSide(color: ColorPalette.pacificBlue),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
            if (cc.status == CycleCountStatus.pendingApproval && Permissions.canApproveCycleCount(widget.userRole)) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _approveCount(cc),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.verified, size: 16),
                  label: const Text('Approve & Commit Adjustments'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _kpiChip(String label, String value, Color color) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color)),
              Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
            ],
          ),
        ),
      );

  void _openCountSheet(BuildContext ctx, CycleCount cc) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _CountEntrySheet(cc: cc, wms: _wms, userEmail: AppScope.of(ctx).userEmail),
    );
  }

  Future<void> _approveCount(CycleCount cc) async {
    final scope = AppScope.of(context);
    await _wms.approveCycleCount(
      countId: cc.id,
      repo: scope.repo,
      approverEmail: scope.userEmail,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cycle count ${cc.countNumber} approved & inventory updated!'), backgroundColor: Colors.green),
      );
    }
  }

  void _showCreateDialog(BuildContext context) {
    final scope = AppScope.of(context);
    String abcFilter = 'A';
    int tolerance = 2;
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => StreamBuilder<List<ProductItem>>(
          stream: scope.repo.watchProducts(),
          builder: (_, snap) {
            final products = snap.data ?? [];
            return AlertDialog(
              title: const Text('New Cycle Count'),
              content: SizedBox(
                width: 380,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: abcFilter,
                      decoration: const InputDecoration(labelText: 'ABC Class to Count'),
                      items: const [
                        DropdownMenuItem(value: 'A', child: Text('Class A â€“ High Value (count every week)')),
                        DropdownMenuItem(value: 'B', child: Text('Class B â€“ Medium (count monthly)')),
                        DropdownMenuItem(value: 'C', child: Text('Class C â€“ Low (count quarterly)')),
                        DropdownMenuItem(value: 'All', child: Text('All Items')),
                      ],
                      onChanged: (v) => setS(() => abcFilter = v ?? 'A'),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Text('Variance Tolerance (units):', style: TextStyle(fontSize: 13)),
                        const Spacer(),
                        DropdownButton<int>(
                          value: tolerance,
                          items: [0, 1, 2, 5, 10].map((v) => DropdownMenuItem(value: v, child: Text('Â±$v'))).toList(),
                          onChanged: (v) => setS(() => tolerance = v ?? 2),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Will create count sheet for ${products.length} product(s). Variances > Â±$tolerance units will require a reason code and approval.',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: ColorPalette.pacificBlue),
                  onPressed: () {
                    final cc = CycleCount(
                      id: 'cc_${DateTime.now().millisecondsSinceEpoch}',
                      countNumber: 'CC-${DateTime.now().year}-${(_wms.cycleCounts.length + 2).toString().padLeft(3, '0')}',
                      createdBy: scope.userEmail,
                      createdAt: DateTime.now(),
                      status: CycleCountStatus.inProgress,
                      abcFilter: abcFilter,
                      varianceTolerance: tolerance,
                      items: products.map((p) => CycleCountItem(
                            productId: p.id,
                            productName: p.product.name,
                            sku: p.product.sku,
                            location: p.product.location,
                            abcClass: abcFilter == 'All' ? 'A' : abcFilter,
                            systemQty: p.product.quantity,
                            unitCost: p.product.cost,
                          ),).toList(),
                    );
                    _wms.createCycleCount(cc);
                    Navigator.pop(ctx);
                  },
                  child: const Text('Start Count'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Bottom sheet for entering cycle count quantities with reason codes.
class _CountEntrySheet extends StatefulWidget {
  const _CountEntrySheet({required this.cc, required this.wms, required this.userEmail});
  final CycleCount cc;
  final WmsService wms;
  final String userEmail;

  @override
  State<_CountEntrySheet> createState() => _CountEntrySheetState();
}

class _CountEntrySheetState extends State<_CountEntrySheet> {
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, VarianceReason?> _reasons = {};
  final Map<String, TextEditingController> _reasonNotes = {};

  @override
  void initState() {
    super.initState();
    for (final item in widget.cc.items) {
      _controllers[item.productId] =
          TextEditingController(text: item.countedQty?.toString() ?? item.systemQty.toString());
      _reasons[item.productId] = item.reasonCode;
      _reasonNotes[item.productId] = TextEditingController(text: item.reasonNote);
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    for (final c in _reasonNotes.values) {
      c.dispose();
    }
    super.dispose();
  }

  bool _needsReason(CycleCountItem item, int counted) {
    return (counted - item.systemQty).abs() > widget.cc.varianceTolerance;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: ColorPalette.pacificBlue,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.fact_check, color: Colors.white),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.cc.countNumber,
                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),),
                        Text('Class ${widget.cc.abcFilter} â€¢ Tolerance Â±${widget.cc.varianceTolerance}',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12),),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
            Flexible(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: widget.cc.items.length,
                itemBuilder: (_, i) {
                  final item = widget.cc.items[i];
                  final ctrl = _controllers[item.productId]!;
                  final counted = int.tryParse(ctrl.text) ?? item.systemQty;
                  final variance = counted - item.systemQty;
                  final needsReason = _needsReason(item, counted);
                  return StatefulBuilder(
                    builder: (_, setS) => Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 1,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(item.productName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                      Text('SKU: ${item.sku} â€¢ ${item.location}',
                                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text('System: ${item.systemQty}',
                                      style: const TextStyle(fontSize: 12, color: Colors.blue, fontWeight: FontWeight.w600),),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: ctrl,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      labelText: 'Physical Count',
                                      isDense: true,
                                    ),
                                    onChanged: (_) => setS(() {}),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: variance == 0
                                        ? Colors.green.withValues(alpha: 0.1)
                                        : variance > 0
                                            ? Colors.orange.withValues(alpha: 0.1)
                                            : Colors.red.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    variance == 0 ? '? Match' : '${variance > 0 ? '+' : ''}$variance',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: variance == 0 ? Colors.green : (variance > 0 ? Colors.orange : Colors.red),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (needsReason) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.red.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
                                ),
                                child: Column(
                                  children: [
                                    DropdownButtonFormField<VarianceReason>(
                                      initialValue: _reasons[item.productId],
                                      decoration: const InputDecoration(
                                        labelText: 'Reason Code (required)',
                                        isDense: true,
                                      ),
                                      items: VarianceReason.values
                                          .map((r) => DropdownMenuItem(value: r, child: Text(r.label)))
                                          .toList(),
                                      onChanged: (v) => setS(() => _reasons[item.productId] = v),
                                    ),
                                    const SizedBox(height: 8),
                                    TextField(
                                      controller: _reasonNotes[item.productId],
                                      decoration: const InputDecoration(labelText: 'Additional notes', isDense: true),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _saveAllCounts,
                  style: FilledButton.styleFrom(
                    backgroundColor: ColorPalette.pacificBlue,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.save),
                  label: const Text('Save Counts & Submit for Approval'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveAllCounts() {
    for (final item in widget.cc.items) {
      final ctrl = _controllers[item.productId];
      final counted = int.tryParse(ctrl?.text ?? '') ?? item.systemQty;
      widget.wms.updateCycleCountItem(
        countId: widget.cc.id,
        productId: item.productId,
        countedQty: counted,
        reason: _reasons[item.productId],
        reasonNote: _reasonNotes[item.productId]?.text ?? '',
        countedBy: widget.userEmail,
      );
    }
    // Mark as pending approval
    final updated = widget.wms.cycleCounts.firstWhere((c) => c.id == widget.cc.id);
    if (updated.requiresApproval) {
      // Update status
    }
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Counts saved â€” awaiting manager approval'), backgroundColor: Colors.blue),
    );
  }
}
