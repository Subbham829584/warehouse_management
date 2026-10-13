import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:warehouse_management/core/app_scope.dart';
import 'package:warehouse_management/core/ui.dart';
import 'package:warehouse_management/models/product.dart';
import 'package:warehouse_management/models/purchase_order.dart';
import 'package:warehouse_management/models/supplier.dart';
import 'package:warehouse_management/services/enterprise_store.dart';
import 'package:warehouse_management/utils/color_palette.dart';

class ProcurementPage extends StatefulWidget {
  const ProcurementPage({super.key});

  @override
  State<ProcurementPage> createState() => _ProcurementPageState();
}

class _ProcurementPageState extends State<ProcurementPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _store = EnterpriseStore.instance;
  String _poFilter = 'all';
  String _supplierSearch = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _store.addListener(_onStoreUpdate);
  }

  void _onStoreUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _store.removeListener(_onStoreUpdate);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final activePOs = _store.purchaseOrders
        .where((p) => p.status == POStatus.ordered || p.status == POStatus.partiallyReceived)
        .toList();
    final totalPendingValue = activePOs.fold(0.0, (acc, p) => acc + p.totalAmount);
    final totalPendingUnits = activePOs.fold(
        0, (acc, p) => acc + (p.totalQuantity - p.totalReceived));

    return Scaffold(
      backgroundColor: ColorPalette.aquaHaze,
      appBar: AppBar(
        title: const Text('Procurement & Suppliers'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: ColorPalette.timberGreen,
          unselectedLabelColor: ColorPalette.timberGreen.withValues(alpha: 0.6),
          indicatorColor: ColorPalette.timberGreen,
          indicatorWeight: 3,
          tabs: [
            Tab(
              icon: const Icon(Icons.receipt_long),
              text: 'Purchase Orders (${_store.purchaseOrders.length})',
            ),
            Tab(
              icon: const Icon(Icons.business),
              text: 'Suppliers (${_store.suppliers.length})',
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Executive KPI Strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: Row(
              children: [
                _buildKpiChip(
                  label: 'Active POs',
                  value: '${activePOs.length}',
                  icon: Icons.pending_actions,
                  color: Colors.blue,
                ),
                const SizedBox(width: 8),
                _buildKpiChip(
                  label: 'Pending Value',
                  value: currency.format(totalPendingValue),
                  icon: Icons.attach_money,
                  color: Colors.green.shade700,
                ),
                const SizedBox(width: 8),
                _buildKpiChip(
                  label: 'Pending Units',
                  value: '$totalPendingUnits pcs',
                  icon: Icons.inventory,
                  color: Colors.orange.shade800,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Tab View
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOrdersTab(context, currency),
                _buildSuppliersTab(context),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (_tabController.index == 0) {
            _showCreatePODialog(context);
          } else {
            _showCreateSupplierDialog(context);
          }
        },
        backgroundColor: ColorPalette.pacificBlue,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          _tabController.index == 0 ? 'New Purchase Order' : 'Add Supplier',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildKpiChip({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
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
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ==================== PURCHASE ORDERS TAB ====================
  Widget _buildOrdersTab(BuildContext context, NumberFormat currency) {
    var list = _store.purchaseOrders;
    if (_poFilter == 'ordered') {
      list = list.where((p) => p.status == POStatus.ordered).toList();
    } else if (_poFilter == 'partiallyReceived') {
      list = list.where((p) => p.status == POStatus.partiallyReceived).toList();
    } else if (_poFilter == 'received') {
      list = list.where((p) => p.status == POStatus.received).toList();
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Filter pills
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterPill('All POs', 'all'),
              const SizedBox(width: 8),
              _buildFilterPill('Ordered', 'ordered'),
              const SizedBox(width: 8),
              _buildFilterPill('Partial Delivery', 'partiallyReceived'),
              const SizedBox(width: 8),
              _buildFilterPill('Completed', 'received'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (list.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: Text(
                'No purchase orders found matching this filter.',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          ...list.map((po) => _buildPOCard(context, po, currency)),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildFilterPill(String title, String key) {
    final selected = _poFilter == key;
    return ChoiceChip(
      label: Text(title),
      selected: selected,
      selectedColor: ColorPalette.pacificBlue.withValues(alpha: 0.2),
      onSelected: (_) => setState(() => _poFilter = key),
    );
  }

  Widget _buildPOCard(
    BuildContext context,
    PurchaseOrder po,
    NumberFormat currency,
  ) {
    Color statusColor;
    String statusText;
    switch (po.status) {
      case POStatus.draft:
        statusColor = Colors.grey;
        statusText = 'Draft';
        break;
      case POStatus.ordered:
        statusColor = Colors.blue;
        statusText = 'Ordered';
        break;
      case POStatus.partiallyReceived:
        statusColor = Colors.orange;
        statusText = 'Partially Received';
        break;
      case POStatus.received:
        statusColor = Colors.green;
        statusText = 'Received in Full';
        break;
      case POStatus.cancelled:
        statusColor = Colors.red;
        statusText = 'Cancelled';
        break;
    }

    final dateFormat = DateFormat('MMM d, yyyy');
    final progress = po.totalQuantity == 0
        ? 0.0
        : (po.totalReceived / po.totalQuantity).clamp(0.0, 1.0);

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
                  child: const Icon(Icons.assignment,
                      color: ColorPalette.pacificBlue, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        po.poNumber,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: ColorPalette.timberGreen,
                        ),
                      ),
                      Text(
                        po.supplierName,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ColorPalette.aquaHaze.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  ...po.items.map((item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                '${item.productName} (x${item.quantity})',
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                            Text(
                              '${item.receivedQuantity}/${item.quantity} rcvd',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: item.receivedQuantity >= item.quantity
                                    ? Colors.green
                                    : Colors.orange.shade800,
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),
            const SizedBox(height: 10),
            // Progress Bar
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
                Text(
                  '${(progress * 100).toInt()}%',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Expected: ${dateFormat.format(po.expectedDate)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                Text(
                  'Total: ${currency.format(po.totalAmount)}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: ColorPalette.timberGreen,
                  ),
                ),
              ],
            ),
            if (po.status != POStatus.received &&
                po.status != POStatus.cancelled) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _showReceiveDialog(context, po),
                  style: FilledButton.styleFrom(
                    backgroundColor: ColorPalette.pacificBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.move_to_inbox, size: 18),
                  label: const Text('Receive Stock into Warehouse'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ==================== RECEIVE DIALOG ====================
  void _showReceiveDialog(BuildContext context, PurchaseOrder po) {
    final scope = AppScope.of(context);
    final unreceivedItems =
        po.items.where((i) => i.receivedQuantity < i.quantity).toList();

    if (unreceivedItems.isEmpty) {
      showMessage(context, 'All items on this PO are already received.');
      return;
    }

    final controllers = <String, TextEditingController>{};
    for (final item in unreceivedItems) {
      final remaining = item.quantity - item.receivedQuantity;
      controllers[item.productId] = TextEditingController(text: '$remaining');
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Receive Stock: ${po.poNumber}'),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter the number of units checked and received into inventory:',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 12),
              ...unreceivedItems.map((item) {
                final remaining = item.quantity - item.receivedQuantity;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.productName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            Text(
                              'Ordered: ${item.quantity} | Remaining: $remaining',
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 80,
                        child: TextField(
                          controller: controllers[item.productId],
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.all(8),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
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
              for (final item in unreceivedItems) {
                final qty =
                    int.tryParse(controllers[item.productId]?.text ?? '') ?? 0;
                if (qty > 0) {
                  await _store.receivePOItems(
                    poId: po.id,
                    productId: item.productId,
                    receiveQty: qty,
                    repo: scope.repo,
                    userEmail: scope.userEmail,
                  );
                }
              }
              if (context.mounted) {
                showMessage(context, 'Stock received & updated in inventory!');
              }
            },
            child: const Text('Confirm & Stock In'),
          ),
        ],
      ),
    );
  }

  // ==================== CREATE PO DIALOG ====================
  void _showCreatePODialog(BuildContext context) {
    final scope = AppScope.of(context);
    final suppliers = _store.suppliers;
    if (suppliers.isEmpty) {
      showMessage(context, 'Please add at least one supplier first.');
      return;
    }

    String selectedSupplierId = suppliers.first.id;
    final poNumberCtrl = TextEditingController(
      text: 'PO-2026-${100 + _store.purchaseOrders.length + 1}',
    );
    final notesCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => StreamBuilder<List<ProductItem>>(
          stream: scope.repo.watchProducts(),
          builder: (ctx, snap) {
            final products = snap.data ?? [];
            return AlertDialog(
              title: const Text('New Purchase Order'),
              content: SizedBox(
                width: 480,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: poNumberCtrl,
                        decoration:
                            const InputDecoration(labelText: 'PO Number'),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: selectedSupplierId,
                        decoration:
                            const InputDecoration(labelText: 'Supplier'),
                        items: suppliers
                            .map((s) => DropdownMenuItem(
                                  value: s.id,
                                  child: Text(s.name),
                                ))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) {
                            setDlgState(() => selectedSupplierId = v);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: notesCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Notes / Instructions',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        products.isEmpty
                            ? 'No products found. Creating sample line item.'
                            : 'Products will be linked from active catalog.',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600),
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
                    final sup =
                        suppliers.firstWhere((s) => s.id == selectedSupplierId);
                    final firstProd = products.isNotEmpty
                        ? products.first
                        : null;
                    final po = PurchaseOrder(
                      id: 'po_${DateTime.now().millisecondsSinceEpoch}',
                      poNumber: poNumberCtrl.text.trim(),
                      supplierId: sup.id,
                      supplierName: sup.name,
                      createdAt: DateTime.now(),
                      expectedDate:
                          DateTime.now().add(Duration(days: sup.leadTimeDays)),
                      status: POStatus.ordered,
                      notes: notesCtrl.text.trim(),
                      items: [
                        POLineItem(
                          productId: firstProd?.id ?? 'demo_1',
                          productName: firstProd?.product.name ?? 'Standard Item',
                          quantity: 50,
                          receivedQuantity: 0,
                          unitCost: firstProd?.product.cost ?? 15.0,
                        ),
                      ],
                    );
                    _store.createPurchaseOrder(po);
                    Navigator.pop(ctx);
                    showMessage(context, 'Purchase Order ${po.poNumber} created!');
                  },
                  child: const Text('Create Order'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ==================== SUPPLIERS TAB ====================
  Widget _buildSuppliersTab(BuildContext context) {
    final list = _store.suppliers.where((s) {
      if (_supplierSearch.isEmpty) return true;
      final q = _supplierSearch.toLowerCase();
      return s.name.toLowerCase().contains(q) ||
          s.category.toLowerCase().contains(q) ||
          s.contactPerson.toLowerCase().contains(q);
    }).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          decoration: InputDecoration(
            hintText: 'Search suppliers by name, category, or contact...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _supplierSearch.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => setState(() => _supplierSearch = ''),
                  )
                : null,
          ),
          onChanged: (v) => setState(() => _supplierSearch = v),
        ),
        const SizedBox(height: 16),
        ...list.map((s) => _buildSupplierCard(context, s)),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildSupplierCard(BuildContext context, Supplier s) {
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
                CircleAvatar(
                  backgroundColor: ColorPalette.nileBlue.withValues(alpha: 0.1),
                  child: Text(
                    s.name.isNotEmpty ? s.name[0] : 'S',
                    style: const TextStyle(
                      color: ColorPalette.nileBlue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: ColorPalette.timberGreen,
                        ),
                      ),
                      Text(
                        'Contact: ${s.contactPerson} • ${s.category}',
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
                    color: Colors.amber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '${s.rating}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.email_outlined,
                    size: 15, color: Colors.grey.shade600),
                const SizedBox(width: 6),
                Text(s.email, style: const TextStyle(fontSize: 12)),
                const Spacer(),
                Icon(Icons.schedule, size: 15, color: Colors.grey.shade600),
                const SizedBox(width: 6),
                Text('${s.leadTimeDays} days lead time',
                    style: const TextStyle(fontSize: 12)),
              ],
            ),
            if (s.address.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.location_on_outlined,
                      size: 15, color: Colors.grey.shade600),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      s.address,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showCreateSupplierDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final contactCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final categoryCtrl = TextEditingController(text: 'General');
    final leadTimeCtrl = TextEditingController(text: '5');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add New Supplier'),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: minAxisSize,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Supplier Name *'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: contactCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Contact Person'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(labelText: 'Email Address'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: phoneCtrl,
                  decoration: const InputDecoration(labelText: 'Phone Number'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: categoryCtrl,
                  decoration: const InputDecoration(labelText: 'Category'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: leadTimeCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'Lead Time (Days)', suffixText: 'days'),
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
            style:
                FilledButton.styleFrom(backgroundColor: ColorPalette.pacificBlue),
            onPressed: () {
              if (nameCtrl.text.trim().isEmpty) return;
              final sup = Supplier(
                id: 'sup_${DateTime.now().millisecondsSinceEpoch}',
                name: nameCtrl.text.trim(),
                contactPerson: contactCtrl.text.trim(),
                email: emailCtrl.text.trim(),
                phone: phoneCtrl.text.trim(),
                category: categoryCtrl.text.trim(),
                leadTimeDays: int.tryParse(leadTimeCtrl.text.trim()) ?? 5,
              );
              _store.addSupplier(sup);
              Navigator.pop(ctx);
              showMessage(context, 'Supplier "${sup.name}" added successfully!');
            },
            child: const Text('Save Supplier'),
          ),
        ],
      ),
    );
  }

  static const minAxisSize = MainAxisSize.min;
}
