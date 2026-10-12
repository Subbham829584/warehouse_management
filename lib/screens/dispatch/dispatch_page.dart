import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:warehouse_management/core/app_scope.dart';
import 'package:warehouse_management/core/ui.dart';
import 'package:warehouse_management/models/dispatch_order.dart';
import 'package:warehouse_management/models/product.dart';
import 'package:warehouse_management/services/enterprise_store.dart';
import 'package:warehouse_management/utils/color_palette.dart';

class DispatchPage extends StatefulWidget {
  const DispatchPage({super.key});

  @override
  State<DispatchPage> createState() => _DispatchPageState();
}

class _DispatchPageState extends State<DispatchPage> {
  final _store = EnterpriseStore.instance;
  String _statusFilter = 'all';

  @override
  void initState() {
    super.initState();
    _store.addListener(_onStoreUpdate);
  }

  void _onStoreUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _store.removeListener(_onStoreUpdate);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final allOrders = _store.dispatchOrders;
    final urgentCount =
        allOrders.where((o) => o.priority == OrderPriority.urgent && o.status != DispatchStatus.dispatched).length;
    final pickingCount =
        allOrders.where((o) => o.status == DispatchStatus.picking).length;
    final packedCount =
        allOrders.where((o) => o.status == DispatchStatus.packed).length;

    var filteredOrders = allOrders;
    if (_statusFilter == 'pending') {
      filteredOrders =
          allOrders.where((o) => o.status == DispatchStatus.pending).toList();
    } else if (_statusFilter == 'picking') {
      filteredOrders =
          allOrders.where((o) => o.status == DispatchStatus.picking).toList();
    } else if (_statusFilter == 'packed') {
      filteredOrders =
          allOrders.where((o) => o.status == DispatchStatus.packed).toList();
    } else if (_statusFilter == 'dispatched') {
      filteredOrders =
          allOrders.where((o) => o.status == DispatchStatus.dispatched).toList();
    }

    return Scaffold(
      backgroundColor: ColorPalette.aquaHaze,
      appBar: AppBar(
        title: const Text('Outbound Orders & Dispatch'),
      ),
      body: Column(
        children: [
          // KPI Metric Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: Row(
              children: [
                _buildMetric(
                  'Urgent Orders',
                  '$urgentCount',
                  Icons.priority_high,
                  Colors.red.shade700,
                ),
                const SizedBox(width: 8),
                _buildMetric(
                  'In Picking',
                  '$pickingCount',
                  Icons.handyman_outlined,
                  Colors.orange.shade800,
                ),
                const SizedBox(width: 8),
                _buildMetric(
                  'Ready to Ship',
                  '$packedCount',
                  Icons.inventory_2_outlined,
                  Colors.blue.shade700,
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
                  _buildFilterChip('All (${allOrders.length})', 'all'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Pending', 'pending'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Picking', 'picking'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Packed', 'packed'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Dispatched', 'dispatched'),
                ],
              ),
            ),
          ),
          // Orders List
          Expanded(
            child: filteredOrders.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: Text(
                        'No dispatch orders found matching this filter.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredOrders.length,
                    itemBuilder: (ctx, i) => _buildOrderCard(
                      context,
                      filteredOrders[i],
                      currency,
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateOrderDialog(context),
        backgroundColor: ColorPalette.pacificBlue,
        icon: const Icon(Icons.local_shipping, color: Colors.white),
        label: const Text(
          'New Dispatch Order',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildMetric(String title, String value, IconData icon, Color color) {
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
                Icon(icon, size: 15, color: color),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    title,
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

  Widget _buildOrderCard(
    BuildContext context,
    DispatchOrder order,
    NumberFormat currency,
  ) {
    Color priorityColor;
    String priorityText;
    switch (order.priority) {
      case OrderPriority.urgent:
        priorityColor = Colors.red;
        priorityText = 'URGENT';
        break;
      case OrderPriority.high:
        priorityColor = Colors.orange.shade800;
        priorityText = 'HIGH';
        break;
      case OrderPriority.normal:
        priorityColor = Colors.blueGrey;
        priorityText = 'NORMAL';
        break;
    }

    final isDispatched = order.status == DispatchStatus.dispatched;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: ColorPalette.nileBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.outbox,
                      color: ColorPalette.nileBlue, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.orderNumber,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: ColorPalette.timberGreen,
                        ),
                      ),
                      Text(
                        order.customerName,
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
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: priorityColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border:
                        Border.all(color: priorityColor.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    priorityText,
                    style: TextStyle(
                      color: priorityColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Destination & Carrier
            Row(
              children: [
                Icon(Icons.pin_drop_outlined,
                    size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    order.destination,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.local_shipping_outlined,
                    size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  order.carrier,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Pick Status Stepper Indicator
            _buildStatusTimeline(order.status),
            const SizedBox(height: 12),
            // Picking Checklist Items
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ColorPalette.aquaHaze.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Order Line Items & Picking Status:',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...order.items.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.productName,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.blueGrey.shade100,
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          'Bin: ${item.binLocation}',
                                          style: const TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Qty required: ${item.quantity}',
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey.shade700),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            if (!isDispatched) ...[
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline,
                                    size: 20),
                                onPressed: item.pickedQuantity > 0
                                    ? () => _store.updateItemPicked(
                                          orderId: order.id,
                                          productId: item.productId,
                                          pickedQty: item.pickedQuantity - 1,
                                        )
                                    : null,
                              ),
                              Text(
                                '${item.pickedQuantity} / ${item.quantity}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: item.isFullyPicked
                                      ? Colors.green
                                      : Colors.black87,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline,
                                    size: 20),
                                onPressed: item.pickedQuantity < item.quantity
                                    ? () => _store.updateItemPicked(
                                          orderId: order.id,
                                          productId: item.productId,
                                          pickedQty: item.pickedQuantity + 1,
                                        )
                                    : null,
                              ),
                            ] else ...[
                              Text(
                                '${item.quantity} pcs (Fulfilled)',
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green),
                              ),
                            ],
                          ],
                        ),
                      )),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (order.trackingNumber.isNotEmpty)
                  Text(
                    'Tracking: ${order.trackingNumber}',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue),
                  )
                else
                  Text(
                    'Created: ${DateFormat('MMM d, h:mm a').format(order.createdAt)}',
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                Text(
                  'Value: ${currency.format(order.totalValue)}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: ColorPalette.timberGreen,
                  ),
                ),
              ],
            ),
            if (!isDispatched) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _confirmDispatch(context, order),
                  style: FilledButton.styleFrom(
                    backgroundColor: ColorPalette.pacificBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.local_shipping, size: 18),
                  label: const Text('Confirm & Dispatch Shipment'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusTimeline(DispatchStatus status) {
    final stages = ['Pending', 'Picking', 'Packed', 'Dispatched'];
    int activeIndex = 0;
    switch (status) {
      case DispatchStatus.pending:
        activeIndex = 0;
        break;
      case DispatchStatus.picking:
        activeIndex = 1;
        break;
      case DispatchStatus.packed:
        activeIndex = 2;
        break;
      case DispatchStatus.dispatched:
      case DispatchStatus.delivered:
        activeIndex = 3;
        break;
      case DispatchStatus.cancelled:
        activeIndex = -1;
        break;
    }

    return Row(
      children: List.generate(stages.length * 2 - 1, (i) {
        if (i.isOdd) {
          final stepIndex = i ~/ 2;
          final isPast = stepIndex < activeIndex;
          return Expanded(
            child: Container(
              height: 3,
              color: isPast ? Colors.green : Colors.grey.shade300,
            ),
          );
        }
        final stageIndex = i ~/ 2;
        final isActive = stageIndex == activeIndex;
        final isPassed = stageIndex < activeIndex;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 9,
              backgroundColor: isPassed
                  ? Colors.green
                  : isActive
                      ? ColorPalette.pacificBlue
                      : Colors.grey.shade300,
              child: isPassed
                  ? const Icon(Icons.check, size: 11, color: Colors.white)
                  : Text(
                      '${stageIndex + 1}',
                      style: const TextStyle(
                          fontSize: 9,
                          color: Colors.white,
                          fontWeight: FontWeight.bold),
                    ),
            ),
            const SizedBox(height: 2),
            Text(
              stages[stageIndex],
              style: TextStyle(
                fontSize: 9,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive ? ColorPalette.timberGreen : Colors.grey.shade600,
              ),
            ),
          ],
        );
      }),
    );
  }

  void _confirmDispatch(BuildContext context, DispatchOrder order) async {
    final scope = AppScope.of(context);
    final ok = await confirm(
      context,
      title: 'Dispatch Order ${order.orderNumber}?',
      message:
          'This will deduct the items from active inventory, update movement logs, and mark this order as Dispatched.',
      confirmLabel: 'Dispatch Shipment',
    );
    if (!ok) return;

    try {
      await _store.dispatchOrder(
        orderId: order.id,
        repo: scope.repo,
        userEmail: scope.userEmail,
      );
      if (context.mounted) {
        showMessage(context, 'Order ${order.orderNumber} dispatched successfully!');
      }
    } catch (e) {
      if (context.mounted) {
        showMessage(context, 'Error dispatching order: $e', error: true);
      }
    }
  }

  void _showCreateOrderDialog(BuildContext context) {
    final scope = AppScope.of(context);
    final orderNumCtrl = TextEditingController(
      text: 'DSP-${9800 + _store.dispatchOrders.length + 1}',
    );
    final customerCtrl = TextEditingController();
    final destinationCtrl = TextEditingController();
    OrderPriority selectedPriority = OrderPriority.normal;
    final carrierCtrl = TextEditingController(text: 'FedEx Express Freight');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => StreamBuilder<List<ProductItem>>(
          stream: scope.repo.watchProducts(),
          builder: (ctx, snap) {
            final products = snap.data ?? [];
            return AlertDialog(
              title: const Text('Create Dispatch Order'),
              content: SizedBox(
                width: 460,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: orderNumCtrl,
                        decoration:
                            const InputDecoration(labelText: 'Order Number *'),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: customerCtrl,
                        decoration:
                            const InputDecoration(labelText: 'Customer / Recipient *'),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: destinationCtrl,
                        decoration: const InputDecoration(
                            labelText: 'Destination City & Hub *'),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<OrderPriority>(
                        value: selectedPriority,
                        decoration:
                            const InputDecoration(labelText: 'Order Priority'),
                        items: const [
                          DropdownMenuItem(
                              value: OrderPriority.normal,
                              child: Text('Normal Priority')),
                          DropdownMenuItem(
                              value: OrderPriority.high,
                              child: Text('High Priority')),
                          DropdownMenuItem(
                              value: OrderPriority.urgent,
                              child: Text('Urgent (Next Flight)')),
                        ],
                        onChanged: (v) {
                          if (v != null) {
                            setDlgState(() => selectedPriority = v);
                          }
                        },
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: carrierCtrl,
                        decoration: const InputDecoration(labelText: 'Carrier'),
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
                    final firstProd = products.isNotEmpty ? products.first : null;
                    final order = DispatchOrder(
                      id: 'dsp_${DateTime.now().millisecondsSinceEpoch}',
                      orderNumber: orderNumCtrl.text.trim(),
                      customerName: customerCtrl.text.trim(),
                      destination: destinationCtrl.text.trim(),
                      createdAt: DateTime.now(),
                      priority: selectedPriority,
                      carrier: carrierCtrl.text.trim(),
                      items: [
                        DispatchLineItem(
                          productId: firstProd?.id ?? 'demo_1',
                          productName: firstProd?.product.name ?? 'Standard Product',
                          quantity: 10,
                          unitPrice: (firstProd?.product.cost ?? 10.0) * 1.4,
                          binLocation: firstProd?.product.location.isNotEmpty == true
                              ? firstProd!.product.location
                              : 'A-01-01',
                        ),
                      ],
                    );
                    _store.createDispatchOrder(order);
                    Navigator.pop(ctx);
                    showMessage(context, 'Dispatch Order ${order.orderNumber} created!');
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
}
