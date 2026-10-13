import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:warehouse_management/core/app_scope.dart';
import 'package:warehouse_management/core/ui.dart';
import 'package:warehouse_management/models/product.dart';
import 'package:warehouse_management/models/return_order.dart';
import 'package:warehouse_management/services/enterprise_store.dart';
import 'package:warehouse_management/utils/color_palette.dart';

class ReturnsPage extends StatefulWidget {
  const ReturnsPage({super.key});

  @override
  State<ReturnsPage> createState() => _ReturnsPageState();
}

class _ReturnsPageState extends State<ReturnsPage> {
  final _store = EnterpriseStore.instance;
  String _statusFilter = 'all';

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
    final currency = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final allRmas = _store.returnOrders;
    final pendingCount = allRmas
        .where((r) =>
            r.status == RmaStatus.requested || r.status == RmaStatus.inspecting)
        .length;
    final restockedCount =
        allRmas.where((r) => r.status == RmaStatus.restocked).length;
    final quarantinedCount =
        allRmas.where((r) => r.status == RmaStatus.quarantined).length;

    var filtered = allRmas;
    if (_statusFilter == 'requested') {
      filtered = allRmas
          .where((r) =>
              r.status == RmaStatus.requested ||
              r.status == RmaStatus.inspecting)
          .toList();
    } else if (_statusFilter == 'restocked') {
      filtered =
          allRmas.where((r) => r.status == RmaStatus.restocked).toList();
    } else if (_statusFilter == 'quarantined') {
      filtered =
          allRmas.where((r) => r.status == RmaStatus.quarantined).toList();
    }

    return Scaffold(
      backgroundColor: ColorPalette.aquaHaze,
      appBar: AppBar(
        title: const Text('Returns & Reverse Logistics (RMA)'),
      ),
      body: Column(
        children: [
          // KPI Metric Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: Row(
              children: [
                _buildKpiCard(
                  'Pending Review',
                  '$pendingCount',
                  Icons.pending_actions,
                  Colors.orange.shade800,
                ),
                const SizedBox(width: 8),
                _buildKpiCard(
                  'Restocked',
                  '$restockedCount',
                  Icons.replay,
                  Colors.green.shade700,
                ),
                const SizedBox(width: 8),
                _buildKpiCard(
                  'Quarantined',
                  '$quarantinedCount',
                  Icons.block_outlined,
                  Colors.red.shade700,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Filter Chips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('All RMAs (${allRmas.length})', 'all'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Pending Inspection', 'requested'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Restocked', 'restocked'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Quarantined', 'quarantined'),
                ],
              ),
            ),
          ),
          // RMA List
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: Text(
                        'No return orders match this filter.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) =>
                        _buildRmaCard(context, filtered[i], currency),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateRmaDialog(context),
        backgroundColor: ColorPalette.pacificBlue,
        icon: const Icon(Icons.assignment_return, color: Colors.white),
        label: const Text(
          'Log Return (RMA)',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildKpiCard(
      String title, String value, IconData icon, Color color) {
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
                    title,
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

  Widget _buildFilterChip(String label, String key) {
    final selected = _statusFilter == key;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: ColorPalette.pacificBlue.withValues(alpha: 0.2),
      onSelected: (_) => setState(() => _statusFilter = key),
    );
  }

  Widget _buildRmaCard(
    BuildContext context,
    ReturnOrder rma,
    NumberFormat currency,
  ) {
    Color statusColor;
    String statusText;
    switch (rma.status) {
      case RmaStatus.requested:
      case RmaStatus.inspecting:
        statusColor = Colors.orange;
        statusText = 'Pending Inspection';
        break;
      case RmaStatus.restocked:
        statusColor = Colors.green;
        statusText = 'Restocked to Shelf';
        break;
      case RmaStatus.quarantined:
        statusColor = Colors.red;
        statusText = 'Quarantined / Damaged';
        break;
      case RmaStatus.scrapped:
        statusColor = Colors.grey;
        statusText = 'Scrapped';
        break;
    }

    String reasonText;
    switch (rma.reason) {
      case ReturnReason.defective:
        reasonText = 'Defective / Faulty';
        break;
      case ReturnReason.wrongItem:
        reasonText = 'Wrong Item Shipped';
        break;
      case ReturnReason.customerRemorse:
        reasonText = 'Customer Remorse (Unopened)';
        break;
      case ReturnReason.damagedInTransit:
        reasonText = 'Damaged in Transit';
        break;
    }

    final isResolved = rma.status == RmaStatus.restocked ||
        rma.status == RmaStatus.quarantined ||
        rma.status == RmaStatus.scrapped;

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
                  child: const Icon(Icons.keyboard_return,
                      color: ColorPalette.pacificBlue, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rma.rmaNumber,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: ColorPalette.timberGreen,
                        ),
                      ),
                      Text(
                        'Customer: ${rma.customerName}',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade700),
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
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
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
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${rma.productName} (x${rma.quantity} pcs)',
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Reason: $reasonText',
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    currency.format(rma.refundAmount),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: ColorPalette.timberGreen,
                    ),
                  ),
                ],
              ),
            ),
            if (rma.inspectionNotes.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                'QC Notes: ${rma.inspectionNotes}',
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
            if (!isResolved) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _showInspectDialog(context, rma),
                  style: FilledButton.styleFrom(
                    backgroundColor: ColorPalette.pacificBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: const Text('Inspect & Resolve Return'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showInspectDialog(BuildContext context, ReturnOrder rma) {
    final scope = AppScope.of(context);
    final notesCtrl = TextEditingController();
    RmaStatus chosenOutcome = RmaStatus.restocked;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: Text('Inspection: ${rma.rmaNumber}'),
          content: SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Item: ${rma.productName} (Qty: ${rma.quantity})',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 14),
                const Text('Inspection Outcome:',
                    style:
                        TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                RadioListTile<RmaStatus>(
                  title: const Text('Passed QC - Restock into Inventory'),
                  subtitle: const Text(
                      'Increments active stock quantity automatically'),
                  value: RmaStatus.restocked,
                  groupValue: chosenOutcome,
                  onChanged: (v) => setDlgState(() => chosenOutcome = v!),
                ),
                RadioListTile<RmaStatus>(
                  title: const Text('Failed QC - Move to Quarantine'),
                  subtitle: const Text(
                      'Keeps item isolated; active stock is not incremented'),
                  value: RmaStatus.quarantined,
                  groupValue: chosenOutcome,
                  onChanged: (v) => setDlgState(() => chosenOutcome = v!),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: notesCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Technician Inspection Notes',
                    hintText: 'e.g. Unopened box, passed continuity testing...',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: ColorPalette.pacificBlue),
              onPressed: () async {
                Navigator.pop(ctx);
                await _store.inspectReturnOrder(
                  rmaId: rma.id,
                  resolution: chosenOutcome,
                  notes: notesCtrl.text.trim().isNotEmpty
                      ? notesCtrl.text.trim()
                      : (chosenOutcome == RmaStatus.restocked
                          ? 'Passed QC and returned to active shelf.'
                          : 'Failed QC, quarantined.'),
                  repo: scope.repo,
                  userEmail: scope.userEmail,
                );
                if (context.mounted) {
                  showMessage(context,
                      'RMA ${rma.rmaNumber} resolved (${chosenOutcome == RmaStatus.restocked ? 'Restocked' : 'Quarantined'})!');
                }
              },
              child: const Text('Confirm Resolution'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateRmaDialog(BuildContext context) {
    final scope = AppScope.of(context);
    final rmaNumCtrl = TextEditingController(
      text: 'RMA-2026-${100 + _store.returnOrders.length + 1}',
    );
    final customerCtrl = TextEditingController();
    final qtyCtrl = TextEditingController(text: '1');
    ReturnReason selectedReason = ReturnReason.defective;

    showDialog(
      context: context,
      builder: (ctx) => StreamBuilder<List<ProductItem>>(
        stream: scope.repo.watchProducts(),
        builder: (ctx, snap) {
          final products = snap.data ?? [];
          String? selectedProdId =
              products.isNotEmpty ? products.first.id : null;

          return StatefulBuilder(
            builder: (ctx, setDlgState) => AlertDialog(
              title: const Text('Log New Return (RMA)'),
              content: SizedBox(
                width: 440,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: rmaNumCtrl,
                        decoration:
                            const InputDecoration(labelText: 'RMA Number'),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: customerCtrl,
                        decoration:
                            const InputDecoration(labelText: 'Customer Name *'),
                      ),
                      const SizedBox(height: 10),
                      if (products.isNotEmpty)
                        DropdownButtonFormField<String>(
                          value: selectedProdId,
                          decoration:
                              const InputDecoration(labelText: 'Returned Product'),
                          items: products
                              .map((p) => DropdownMenuItem(
                                    value: p.id,
                                    child: Text(
                                      p.product.name,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ))
                              .toList(),
                          onChanged: (v) =>
                              setDlgState(() => selectedProdId = v),
                        ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: qtyCtrl,
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(labelText: 'Quantity Returned'),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<ReturnReason>(
                        value: selectedReason,
                        decoration:
                            const InputDecoration(labelText: 'Return Reason'),
                        items: const [
                          DropdownMenuItem(
                              value: ReturnReason.defective,
                              child: Text('Defective / Malfunctioning')),
                          DropdownMenuItem(
                              value: ReturnReason.wrongItem,
                              child: Text('Wrong Item Shipped')),
                          DropdownMenuItem(
                              value: ReturnReason.customerRemorse,
                              child: Text('Customer Remorse (Unopened)')),
                          DropdownMenuItem(
                              value: ReturnReason.damagedInTransit,
                              child: Text('Damaged in Transit')),
                        ],
                        onChanged: (v) {
                          if (v != null) {
                            setDlgState(() => selectedReason = v);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                      backgroundColor: ColorPalette.pacificBlue),
                  onPressed: () {
                    if (customerCtrl.text.trim().isEmpty) return;
                    final prod = selectedProdId != null
                        ? products.firstWhere((p) => p.id == selectedProdId)
                        : null;
                    final qty = int.tryParse(qtyCtrl.text.trim()) ?? 1;

                    final rma = ReturnOrder(
                      id: 'rma_${DateTime.now().millisecondsSinceEpoch}',
                      rmaNumber: rmaNumCtrl.text.trim(),
                      customerName: customerCtrl.text.trim(),
                      productId: prod?.id ?? 'demo_1',
                      productName: prod?.product.name ?? 'Standard Item',
                      quantity: qty,
                      reason: selectedReason,
                      createdAt: DateTime.now(),
                      refundAmount: (prod?.product.cost ?? 15.0) * qty,
                    );
                    _store.createReturnOrder(rma);
                    Navigator.pop(ctx);
                    showMessage(context, 'RMA ${rma.rmaNumber} created!');
                  },
                  child: const Text('Log Return'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
