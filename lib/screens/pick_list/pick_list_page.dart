import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:warehouse_management/core/app_scope.dart';
import 'package:warehouse_management/models/pick_list.dart';
import 'package:warehouse_management/models/product.dart';
import 'package:warehouse_management/services/wms_service.dart';
import 'package:warehouse_management/utils/color_palette.dart';

class PickListPage extends StatefulWidget {
  const PickListPage({super.key});

  @override
  State<PickListPage> createState() => _PickListPageState();
}

class _PickListPageState extends State<PickListPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wms = WmsService.instance;

    return ListenableBuilder(
      listenable: wms,
      builder: (context, _) {
        final allPicks = wms.pickLists;
        final pending = allPicks.where((p) => p.status == PickStatus.pending).toList();
        final inProgress = allPicks.where((p) => p.status == PickStatus.inProgress).toList();
        final completed = allPicks.where((p) => p.status == PickStatus.completed).toList();

        return Scaffold(
          appBar: AppBar(
            title: const Text('Pick Lists & Wave Picking'),
            actions: [
              IconButton(
                tooltip: 'Picking Method Info',
                icon: const Icon(Icons.info_outline),
                onPressed: () => _showMethodInfo(context),
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabs: [
                Tab(text: 'All (${allPicks.length})'),
                Tab(text: 'Pending (${pending.length})'),
                Tab(text: 'In Progress (${inProgress.length})'),
                Tab(text: 'Completed (${completed.length})'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildPickList(context, allPicks),
              _buildPickList(context, pending),
              _buildPickList(context, inProgress),
              _buildPickList(context, completed),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(heroTag: null,
            icon: const Icon(Icons.playlist_add),
            label: const Text('Create Pick List'),
            backgroundColor: ColorPalette.nileBlue,
            foregroundColor: Colors.white,
            onPressed: () => _showCreatePickListSheet(context),
          ),
        );
      },
    );
  }

  Widget _buildPickList(BuildContext context, List<PickList> list) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_sharp, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text('No pick lists found', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
            const SizedBox(height: 6),
            const Text('Generate wave/zone pick lists for outgoing orders.', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (ctx, i) => _buildCard(ctx, list[i]),
    );
  }

  Widget _buildCard(BuildContext ctx, PickList pl) {
    final statusColor = switch (pl.status) {
      PickStatus.pending => Colors.orange,
      PickStatus.inProgress => Colors.blue,
      PickStatus.completed => Colors.green,
      PickStatus.cancelled => Colors.grey,
    };
    final progress = pl.totalLines == 0 ? 0.0 : (pl.pickedLines / pl.totalLines).clamp(0.0, 1.0);

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openPickExecutionSheet(ctx, pl),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: ColorPalette.nileBlue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          pl.pickNumber,
                          style: const TextStyle(fontWeight: FontWeight.bold, color: ColorPalette.nileBlue),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (pl.filterZone.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.purple.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.purple.shade200),
                          ),
                          child: Text(
                            pl.filterZone,
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.purple.shade800),
                          ),
                        ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      pl.status.label,
                      style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Order: ${pl.orderId} - ${pl.customerName}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.person_outline, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text('Picker: ${pl.assignedTo}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  const Spacer(),
                  const Icon(Icons.access_time, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(DateFormat('dd MMM, hh:mm a').format(pl.createdAt), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation(progress == 1.0 ? Colors.green : ColorPalette.nileBlue),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${pl.pickedLines} of ${pl.totalLines} lines picked (${(progress * 100).toInt()}%)',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                  ),
                  const Row(
                    children: [
                      Text('Start Walk', style: TextStyle(color: ColorPalette.nileBlue, fontWeight: FontWeight.bold, fontSize: 13)),
                      Icon(Icons.arrow_forward_ios, size: 12, color: ColorPalette.nileBlue),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openPickExecutionSheet(BuildContext ctx, PickList pl) {
    // Show picker sheet sorted by bin sequence for optimal walk path
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => _PickExecutionView(pickListId: pl.id),
    );
  }

  void _showMethodInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.route, color: ColorPalette.nileBlue),
            SizedBox(width: 8),
            Text('WMS Picking Methods'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('â€¢ Zone Picking:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('The warehouse is partitioned into distinct zones (e.g. Zone A, Zone B). Pickers stay in their zone and pick only designated SKU lines.', style: TextStyle(fontSize: 13)),
            SizedBox(height: 10),
            Text('â€¢ Bin-Sequence Walk Path:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('Pick lines are strictly ordered by bin address (A-01 -> A-02) so the picker never doubles back or wastes steps.', style: TextStyle(fontSize: 13)),
            SizedBox(height: 10),
            Text('â€¢ Wave / Batch Picking:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('Multiple customer orders are combined into a single wave release to maximize picking density.', style: TextStyle(fontSize: 13)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Got it')),
        ],
      ),
    );
  }

  void _showCreatePickListSheet(BuildContext context) {
    final repo = AppScope.of(context).repo;
    final orderIdCtrl = TextEditingController(text: 'ORD-${DateTime.now().millisecondsSinceEpoch % 10000}');
    final customerCtrl = TextEditingController(text: 'FastTrack Logistics');
    final pickerCtrl = TextEditingController(text: 'picker@warehouse.io');
    String chosenZone = 'All Zones';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return StreamBuilder<List<ProductItem>>(
              stream: repo.watchProducts(),
              builder: (ctx, snap) {
                final products = (snap.data ?? []).where((p) => p.product.quantity > 0).toList();

                return Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
                    top: 24,
                    left: 20,
                    right: 20,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Generate Pick List',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: ColorPalette.timberGreen),
                        ),
                        const SizedBox(height: 6),
                        const Text('Generates bin-sequenced walk paths for warehouse staff.', style: TextStyle(color: Colors.grey, fontSize: 13)),
                        const SizedBox(height: 16),
                        TextField(
                          controller: orderIdCtrl,
                          decoration: const InputDecoration(labelText: 'Order / Wave Reference', border: OutlineInputBorder()),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: customerCtrl,
                          decoration: const InputDecoration(labelText: 'Customer / Dispatch Destination', border: OutlineInputBorder()),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: chosenZone,
                          decoration: const InputDecoration(labelText: 'Picking Strategy / Zone', border: OutlineInputBorder()),
                          items: const [
                            DropdownMenuItem(value: 'All Zones', child: Text('All Zones (Full Warehouse Wave)')),
                            DropdownMenuItem(value: 'Zone A', child: Text('Zone A - Fast Movers (Velocity)')),
                            DropdownMenuItem(value: 'Zone B', child: Text('Zone B - Medium Movers')),
                            DropdownMenuItem(value: 'Zone C', child: Text('Zone C - Bulk / Cold Storage')),
                          ],
                          onChanged: (v) => setLocal(() => chosenZone = v ?? 'All Zones'),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: pickerCtrl,
                          decoration: const InputDecoration(labelText: 'Assign to Picker', border: OutlineInputBorder()),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: ColorPalette.nileBlue,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            icon: const Icon(Icons.check_circle),
                            label: const Text('Generate Pick Walk', style: TextStyle(fontSize: 16)),
                            onPressed: () {
                              if (products.isEmpty) {
                                Navigator.pop(sheetCtx);
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No products with stock available')));
                                return;
                              }

                              final pickItems = products.take(4).map((p) {
                                final bin = p.product.location.isNotEmpty ? p.product.location : 'A-01-S1';
                                return PickLineItem(
                                  productId: p.id,
                                  productName: p.product.name,
                                  sku: p.product.sku,
                                  zone: chosenZone == 'All Zones' ? 'Zone A' : chosenZone,
                                  binCode: bin,
                                  qtyRequired: (p.product.quantity > 5 ? 5 : p.product.quantity).clamp(1, 100),
                                  lotNumber: 'LOT-2026-${p.id.substring(0, p.id.length > 4 ? 4 : p.id.length).toUpperCase()}',
                                );
                              }).toList();

                              final newPl = PickList(
                                id: 'pl_${DateTime.now().millisecondsSinceEpoch}',
                                pickNumber: 'PICK-2026-${(DateTime.now().millisecondsSinceEpoch % 1000).toString().padLeft(3, '0')}',
                                orderId: orderIdCtrl.text.trim(),
                                customerName: customerCtrl.text.trim(),
                                assignedTo: pickerCtrl.text.trim(),
                                createdAt: DateTime.now(),
                                filterZone: chosenZone == 'All Zones' ? '' : chosenZone,
                                items: pickItems,
                              );

                              WmsService.instance.createPickList(newPl);
                              Navigator.pop(sheetCtx);
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Created ${newPl.pickNumber} with ${pickItems.length} bin-sorted pick lines')));
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _PickExecutionView extends StatefulWidget {
  const _PickExecutionView({required this.pickListId});
  final String pickListId;

  @override
  State<_PickExecutionView> createState() => _PickExecutionViewState();
}

class _PickExecutionViewState extends State<_PickExecutionView> {
  @override
  Widget build(BuildContext context) {
    final wms = WmsService.instance;

    return ListenableBuilder(
      listenable: wms,
      builder: (context, _) {
        final pl = wms.pickLists.firstWhere((p) => p.id == widget.pickListId, orElse: () => wms.pickLists.first);
        final sortedLines = pl.sortedByBin;

        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (ctx, scrollCtrl) {
            return DecoratedBox(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(pl.pickNumber, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: ColorPalette.timberGreen)),
                            Text('Order: ${pl.orderId} - ${pl.customerName}', style: const TextStyle(fontSize: 13, color: Colors.grey)),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.teal.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.teal.shade200),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.directions_walk, size: 14, color: Colors.teal),
                              SizedBox(width: 4),
                              Text('Bin-Walk Order', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.teal)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollCtrl,
                      padding: const EdgeInsets.all(16),
                      itemCount: sortedLines.length,
                      itemBuilder: (ctx, idx) {
                        final item = sortedLines[idx];
                        return _buildPickLineTile(ctx, pl, item, idx + 1);
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPickLineTile(BuildContext ctx, PickList pl, PickLineItem item, int seq) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: item.isPicked ? Colors.green.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: item.isPicked ? Colors.green.shade300 : Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stop # badge
            CircleAvatar(
              radius: 14,
              backgroundColor: item.isPicked ? Colors.green : ColorPalette.nileBlue,
              child: Text('$seq', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blueGrey.shade800,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'BIN: ${item.binCode}',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Text(
                        item.isPicked ? 'PICKED' : 'PENDING',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: item.isPicked ? Colors.green.shade700 : Colors.orange.shade800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(item.productName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text('SKU: ${item.sku} | Lot: ${item.lotNumber}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Req: ${item.qtyRequired} units',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      if (!item.isPicked)
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff2e9e6b),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: const Icon(Icons.check, size: 16),
                          label: const Text('Confirm Pick'),
                          onPressed: () {
                            WmsService.instance.markItemPicked(
                              pickListId: pl.id,
                              productId: item.productId,
                              qtyPicked: item.qtyRequired,
                            );
                          },
                        )
                      else
                        const Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green, size: 18),
                            SizedBox(width: 4),
                            Text('Picked', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
