import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:warehouse_management/core/app_scope.dart';
import 'package:warehouse_management/models/grn.dart';
import 'package:warehouse_management/models/product.dart';
import 'package:warehouse_management/services/wms_service.dart';
import 'package:warehouse_management/utils/color_palette.dart';

/// GRN page â€” Receive goods against a Purchase Order.
/// Shows: ordered vs received, lot number entry, discrepancy reason, put-away bin suggestion.
class GrnPage extends StatefulWidget {
  const GrnPage({super.key});

  @override
  State<GrnPage> createState() => _GrnPageState();
}

class _GrnPageState extends State<GrnPage> {
  final _wms = WmsService.instance;

  @override
  void initState() {
    super.initState();
    _wms.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _wms.removeListener(_refresh);
    super.dispose();
  }

  Color _statusColor(GrnStatus s) => switch (s) {
        GrnStatus.draft => Colors.grey,
        GrnStatus.inProgress => Colors.blue,
        GrnStatus.completed => Colors.green,
        GrnStatus.discrepancy => Colors.orange,
      };

  @override
  Widget build(BuildContext context) {
    final grns = _wms.grns;
    return Scaffold(
      backgroundColor: ColorPalette.aquaHaze,
      body: grns.isEmpty
          ? _buildEmpty()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: grns.length,
              itemBuilder: (ctx, i) => _buildGrnCard(ctx, grns[i]),
            ),
      floatingActionButton: FloatingActionButton.extended(heroTag: null,
        onPressed: () => _showCreateGrnDialog(context),
        backgroundColor: ColorPalette.pacificBlue,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New GRN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildEmpty() => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.move_to_inbox_outlined, size: 72, color: Colors.grey),
            SizedBox(height: 12),
            Text('No GRNs yet', style: TextStyle(fontSize: 18, color: Colors.grey)),
            SizedBox(height: 6),
            Text('Tap + to receive goods against a PO', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );

  Widget _buildGrnCard(BuildContext ctx, GoodsReceivedNote grn) {
    final sc = _statusColor(grn.status);
    final pct = grn.totalOrdered == 0 ? 0.0 : (grn.totalReceived / grn.totalOrdered).clamp(0.0, 1.0);
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
                  child: const Icon(Icons.assignment_turned_in, color: ColorPalette.pacificBlue, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(grn.grnNumber,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ColorPalette.timberGreen),),
                      Text('${grn.poNumber} â€¢ ${grn.supplierName}',
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
                  child: Text(grn.status.label, style: TextStyle(color: sc, fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Items list
            ...grn.items.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.productName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            if (item.lotNumber.isNotEmpty)
                              Text('Lot: ${item.lotNumber}', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                            if (item.putAwayBin.isNotEmpty)
                              Text('Put-away: ${item.putAwayBin}',
                                  style: const TextStyle(fontSize: 11, color: ColorPalette.pacificBlue, fontWeight: FontWeight.w600),),
                            if (item.hasDiscrepancy && item.discrepancyReason.isNotEmpty)
                              Text('? ${item.discrepancyReason}',
                                  style: const TextStyle(fontSize: 11, color: Colors.orange),),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('${item.receivedQty}/${item.orderedQty}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: item.hasDiscrepancy ? Colors.orange : Colors.green,
                              ),),
                          Text('Received/Ordered', style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                        ],
                      ),
                    ],
                  ),
                ),),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct,
                      backgroundColor: Colors.grey.shade200,
                      color: pct >= 1.0 ? Colors.green : ColorPalette.pacificBlue,
                      minHeight: 6,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text('${(pct * 100).toInt()}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Received by: ${grn.receivedBy} â€¢ ${DateFormat('MMM d, yyyy').format(grn.receivedAt)}',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
            if (grn.status == GrnStatus.inProgress) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _completeGrn(grn),
                  style: FilledButton.styleFrom(
                    backgroundColor: ColorPalette.pacificBlue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.check_circle, size: 16),
                  label: const Text('Complete GRN & Stock In'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _completeGrn(GoodsReceivedNote grn) async {
    final scope = AppScope.of(context);
    await _wms.completeGrn(grnId: grn.id, repo: scope.repo, userEmail: scope.userEmail);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('GRN ${grn.grnNumber} completed. Stock updated!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _showCreateGrnDialog(BuildContext context) {
    final scope = AppScope.of(context);
    showDialog(
      context: context,
      builder: (_) => StreamBuilder<List<ProductItem>>(
        stream: scope.repo.watchProducts(),
        builder: (ctx, snap) {
          final products = snap.data ?? [];
          return _CreateGrnDialog(products: products, wms: _wms, userEmail: scope.userEmail);
        },
      ),
    );
  }
}

class _CreateGrnDialog extends StatefulWidget {
  const _CreateGrnDialog({required this.products, required this.wms, required this.userEmail});
  final List<ProductItem> products;
  final WmsService wms;
  final String userEmail;

  @override
  State<_CreateGrnDialog> createState() => _CreateGrnDialogState();
}

class _CreateGrnDialogState extends State<_CreateGrnDialog> {
  ProductItem? _selectedProduct;
  final _orderedCtrl = TextEditingController(text: '10');
  final _receivedCtrl = TextEditingController(text: '10');
  final _lotCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();
  String _suggestedBin = '';

  @override
  void dispose() {
    _orderedCtrl.dispose();
    _receivedCtrl.dispose();
    _lotCtrl.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  void _updateBinSuggestion() {
    if (_selectedProduct != null) {
      setState(() {
        _suggestedBin = widget.wms.suggestBin(_selectedProduct!.product.group,
            int.tryParse(_receivedCtrl.text) ?? 0,);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ordered = int.tryParse(_orderedCtrl.text) ?? 0;
    final received = int.tryParse(_receivedCtrl.text) ?? 0;
    final hasDiscrepancy = received != ordered;

    return AlertDialog(
      title: const Text('New Goods Received Note (GRN)'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<ProductItem>(
                decoration: const InputDecoration(labelText: 'Product'),
                items: widget.products
                    .map((p) => DropdownMenuItem(value: p, child: Text(p.product.name, overflow: TextOverflow.ellipsis)))
                    .toList(),
                onChanged: (p) {
                  setState(() => _selectedProduct = p);
                  _updateBinSuggestion();
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _orderedCtrl,
                      decoration: const InputDecoration(labelText: 'Ordered Qty'),
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _receivedCtrl,
                      decoration: const InputDecoration(labelText: 'Received Qty'),
                      keyboardType: TextInputType.number,
                      onChanged: (_) {
                        setState(() {});
                        _updateBinSuggestion();
                      },
                    ),
                  ),
                ],
              ),
              if (hasDiscrepancy) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '? Variance: ${received - ordered} units',
                        style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _reasonCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Reason for discrepancy (required)',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              TextField(
                controller: _lotCtrl,
                decoration: const InputDecoration(labelText: 'Lot / Batch Number'),
              ),
              if (_suggestedBin.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: ColorPalette.pacificBlue.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: ColorPalette.pacificBlue.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on, color: ColorPalette.pacificBlue, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Suggested Put-away Bin',
                                style: TextStyle(fontSize: 11, color: Colors.grey),),
                            Text(_suggestedBin,
                                style: const TextStyle(
                                    color: ColorPalette.timberGreen,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,),),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: ColorPalette.pacificBlue),
          onPressed: _selectedProduct == null
              ? null
              : () {
                  final ord = int.tryParse(_orderedCtrl.text) ?? 0;
                  final rcv = int.tryParse(_receivedCtrl.text) ?? 0;
                  if (hasDiscrepancy && _reasonCtrl.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter a reason for the discrepancy')),
                    );
                    return;
                  }
                  final grn = GoodsReceivedNote(
                    id: 'grn_${DateTime.now().millisecondsSinceEpoch}',
                    grnNumber: 'GRN-${DateTime.now().year}-${(WmsService.instance.grns.length + 2).toString().padLeft(3, '0')}',
                    poId: 'manual',
                    poNumber: 'Manual Receipt',
                    supplierId: 'manual',
                    supplierName: 'Direct Receipt',
                    receivedBy: widget.userEmail,
                    receivedAt: DateTime.now(),
                    items: [
                      GrnLineItem(
                        productId: _selectedProduct!.id,
                        productName: _selectedProduct!.product.name,
                        sku: _selectedProduct!.product.sku,
                        orderedQty: ord,
                        receivedQty: rcv,
                        lotNumber: _lotCtrl.text.trim(),
                        discrepancyReason: _reasonCtrl.text.trim(),
                        putAwayBin: _suggestedBin,
                      ),
                    ],
                  );
                  widget.wms.createGrn(grn);
                  Navigator.pop(context);
                },
          child: const Text('Create GRN'),
        ),
      ],
    );
  }
}
