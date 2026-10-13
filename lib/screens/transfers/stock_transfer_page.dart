import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:warehouse_management/core/app_scope.dart';
import 'package:warehouse_management/models/product.dart';
import 'package:warehouse_management/utils/color_palette.dart';

class BinTransferRecord {
  const BinTransferRecord({
    required this.id,
    required this.productName,
    required this.sku,
    required this.sourceBin,
    required this.targetBin,
    required this.qty,
    required this.reason,
    required this.user,
    required this.timestamp,
  });

  final String id;
  final String productName;
  final String sku;
  final String sourceBin;
  final String targetBin;
  final int qty;
  final String reason;
  final String user;
  final DateTime timestamp;
}

class StockTransferPage extends StatefulWidget {
  const StockTransferPage({super.key});

  @override
  State<StockTransferPage> createState() => _StockTransferPageState();
}

class _StockTransferPageState extends State<StockTransferPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _qtyCtrl = TextEditingController(text: '5');
  final _reasonCtrl = TextEditingController(text: 'Fast-mover zone replenishment');
  String _sourceBin = 'A-01-S1 (Zone A)';
  String _targetBin = 'B-02-S2 (Zone B)';
  String _selectedReasonCode = 'Replenishment';
  String? _selectedProductId;

  final List<BinTransferRecord> _history = [
    BinTransferRecord(
      id: 'TR-101',
      productName: 'Heavy Duty Bearings',
      sku: 'SKU-BRG-01',
      sourceBin: 'A-01-S1 (Zone A)',
      targetBin: 'B-02-S2 (Zone B)',
      qty: 15,
      reason: 'Zone rebalancing',
      user: 'admin@warehouse.io',
      timestamp: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    BinTransferRecord(
      id: 'TR-100',
      productName: 'Castrol Industrial Oil 20L',
      sku: 'SKU-OIL-99',
      sourceBin: 'C-03-S1 (Zone C)',
      targetBin: 'A-04-S3 (Zone A)',
      qty: 8,
      reason: 'Fast-mover velocity relocation',
      user: 'manager@warehouse.io',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  final List<String> _bins = [
    'A-01-S1 (Zone A)',
    'A-02-S1 (Zone A)',
    'A-03-S2 (Zone A)',
    'B-01-S1 (Zone B)',
    'B-02-S2 (Zone B)',
    'B-03-S3 (Zone B)',
    'C-01-S1 (Zone C Bulk)',
    'C-02-S2 (Zone C Bulk)',
  ];

  final List<String> _reasonCodes = [
    'Replenishment',
    'Zone rebalancing',
    'Consolidation',
    'Damaged area relocation',
    'Velocity / ABC Slotting',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _qtyCtrl.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = AppScope.of(context).repo;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bin & Zone Transfer'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            const Tab(text: 'Transfer Stock'),
            Tab(text: 'History (${_history.length})'),
          ],
        ),
      ),
      body: StreamBuilder<List<ProductItem>>(
        stream: repo.watchProducts(),
        builder: (context, snap) {
          final products = snap.data ?? [];
          if (_selectedProductId == null && products.isNotEmpty) {
            _selectedProductId = products.first.id;
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildTransferForm(context, products),
              _buildHistoryList(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTransferForm(BuildContext context, List<ProductItem> products) {
    if (products.isEmpty) {
      return const Center(child: Text('No products available for transfer.'));
    }

    final selectedItem = products.firstWhere(
      (p) => p.id == _selectedProductId,
      orElse: () => products.first,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Select Item to Relocate', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: ColorPalette.timberGreen)),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedProductId,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Product', border: OutlineInputBorder()),
                    items: products.map((p) {
                      return DropdownMenuItem(
                        value: p.id,
                        child: Text('${p.product.name} (Qty: ${p.product.quantity})', overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (v) => setState(() => _selectedProductId = v),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Current Available Stock: ${selectedItem.product.quantity} units', style: TextStyle(color: Colors.blue.shade900, fontWeight: FontWeight.bold, fontSize: 13)),
                        Text('Current Location: ${selectedItem.product.location.isEmpty ? 'A-01-S1' : selectedItem.product.location}', style: TextStyle(color: Colors.blue.shade800, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Source & Destination Bins', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: ColorPalette.timberGreen)),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _sourceBin,
                          isExpanded: true,
                          decoration: const InputDecoration(labelText: 'From Bin', border: OutlineInputBorder()),
                          items: _bins.map((b) => DropdownMenuItem(value: b, child: Text(b, style: const TextStyle(fontSize: 12)))).toList(),
                          onChanged: (v) => setState(() => _sourceBin = v ?? _bins.first),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(Icons.arrow_forward, color: ColorPalette.nileBlue),
                      ),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _targetBin,
                          isExpanded: true,
                          decoration: const InputDecoration(labelText: 'To Bin', border: OutlineInputBorder()),
                          items: _bins.map((b) => DropdownMenuItem(value: b, child: Text(b, style: const TextStyle(fontSize: 12)))).toList(),
                          onChanged: (v) => setState(() => _targetBin = v ?? _bins.last),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _qtyCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Transfer Quantity (units)',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.pin),
                    ),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedReasonCode,
                    decoration: const InputDecoration(labelText: 'Reason Code (Mandatory in WMS)', border: OutlineInputBorder()),
                    items: _reasonCodes.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                    onChanged: (v) => setState(() => _selectedReasonCode = v ?? _reasonCodes.first),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _reasonCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Notes / Justification',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: ColorPalette.nileBlue,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.swap_horiz),
                      label: const Text('Execute Stock Transfer', style: TextStyle(fontSize: 16)),
                      onPressed: () => _executeTransfer(context, selectedItem),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _executeTransfer(BuildContext context, ProductItem item) {
    final qty = int.tryParse(_qtyCtrl.text.trim()) ?? 0;
    if (qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid transfer quantity')));
      return;
    }
    if (_sourceBin == _targetBin) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Source bin and destination bin must be different')));
      return;
    }

    final newRec = BinTransferRecord(
      id: 'TR-${DateTime.now().millisecondsSinceEpoch % 10000}',
      productName: item.product.name,
      sku: item.product.sku,
      sourceBin: _sourceBin,
      targetBin: _targetBin,
      qty: qty,
      reason: '$_selectedReasonCode: ${_reasonCtrl.text.trim()}',
      user: AppScope.of(context).userEmail,
      timestamp: DateTime.now(),
    );

    setState(() {
      _history.insert(0, newRec);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Transferred $qty units of ${item.product.name} from $_sourceBin to $_targetBin')),
    );
    _tabController.animateTo(1);
  }

  Widget _buildHistoryList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _history.length,
      itemBuilder: (ctx, i) {
        final rec = _history[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 1,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(rec.id, style: const TextStyle(fontWeight: FontWeight.bold, color: ColorPalette.nileBlue)),
                    Text(DateFormat('dd MMM yyyy, hh:mm a').format(rec.timestamp), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(rec.productName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text('SKU: ${rec.sku}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Text(rec.sourceBin, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                      const Icon(Icons.arrow_forward, size: 16, color: Colors.grey),
                      Text(rec.targetBin, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.teal)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: ColorPalette.nileBlue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                        child: Text('${rec.qty} units', style: const TextStyle(fontWeight: FontWeight.bold, color: ColorPalette.nileBlue, fontSize: 11)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text('Reason: ${rec.reason}', style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
                Text('Operator: ${rec.user}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
        );
      },
    );
  }
}
