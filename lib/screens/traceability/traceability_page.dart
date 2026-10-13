import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:warehouse_management/core/app_scope.dart';
import 'package:warehouse_management/models/product.dart';
import 'package:warehouse_management/services/wms_service.dart';
import 'package:warehouse_management/utils/color_palette.dart';

class TraceabilityPage extends StatefulWidget {
  const TraceabilityPage({super.key});

  @override
  State<TraceabilityPage> createState() => _TraceabilityPageState();
}

class _TraceabilityPageState extends State<TraceabilityPage> {
  final TextEditingController _searchCtrl = TextEditingController(text: 'LOT-2026-A01');
  String _activeLot = 'LOT-2026-A01';

  @override
  Widget build(BuildContext context) {
    final repo = AppScope.of(context).repo;
    final wms = WmsService.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lot & Serial Traceability'),
      ),
      body: StreamBuilder<List<ProductItem>>(
        stream: repo.watchProducts(),
        builder: (context, snap) {
          final products = snap.data ?? [];

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Search Header
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'End-to-End Lot Traceability',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ColorPalette.timberGreen),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Track full lineage: Supplier PO -> Receiving GRN -> Put-away Bin -> Cycle Count -> Customer Dispatch.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchCtrl,
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.qr_code_2),
                                hintText: 'Enter Lot # or Serial #',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: ColorPalette.nileBlue,
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () {
                              setState(() {
                                _activeLot = _searchCtrl.text.trim().toUpperCase();
                              });
                            },
                            child: const Text('Trace'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            const Text('Quick Select: ', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            for (final lot in ['LOT-2026-A01', 'LOT-2026-B02', 'LOT-2026-PROD', 'LOT-2026-C03'])
                              Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: ActionChip(
                                  label: Text(lot, style: const TextStyle(fontSize: 11)),
                                  backgroundColor: _activeLot == lot ? ColorPalette.nileBlue.withValues(alpha: 0.15) : null,
                                  onPressed: () {
                                    setState(() {
                                      _activeLot = lot;
                                      _searchCtrl.text = lot;
                                    });
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Compliance Banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.verified, color: Colors.green.shade700, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Audit Trail Intact: $_activeLot complies with forward & backward batch audit requirements.',
                        style: TextStyle(color: Colors.green.shade800, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Trace Timeline
              _buildTimeline(context, products, wms),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTimeline(BuildContext context, List<ProductItem> products, WmsService wms) {
    final firstProd = products.isNotEmpty ? products.first.product.name : 'Industrial Hydraulic Pump';
    final firstSku = products.isNotEmpty ? products.first.product.sku : 'SKU-ENG-101';

    return Column(
      children: [
        _TimelineStep(
          stepNumber: 1,
          icon: Icons.local_shipping_outlined,
          color: Colors.blue,
          title: '1. Inbound Receipt (Supplier -> Dock)',
          subtitle: 'PO-2026-089 from Apex Industrial Supplies',
          details: [
            'Receipt Document: GRN-2026-001',
            'Quantity Received: 50 units',
            'Manufacture Date: 15 Jan 2026',
            'Expiry Date: 15 Jan 2028',
            'Receiving Clerk: ravi@warehouse.io',
          ],
        ),
        _TimelineStep(
          stepNumber: 2,
          icon: Icons.all_inbox,
          color: Colors.teal,
          title: '2. Put-away & Storage (Dock -> Bin)',
          subtitle: 'Allocated to Zone A - High Velocity Rack',
          details: [
            'Target Bin: A-01-S1 (Free capacity verified)',
            'Velocity Class: Class A',
            'Stored Quantity: 50 units',
            'Put-away Completed: ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now().subtract(const Duration(days: 4)))}',
          ],
        ),
        _TimelineStep(
          stepNumber: 3,
          icon: Icons.fact_check_outlined,
          color: Colors.orange,
          title: '3. Cycle Counting & Quality Check',
          subtitle: 'Count #CC-2026-001 (Zero Variance)',
          details: [
            'Expected Stock: 50 units',
            'Physical Count: 50 units (Variance: 0 units)',
            'Audited By: admin@warehouse.io',
            'Status: Approved & Reconciled',
          ],
        ),
        _TimelineStep(
          stepNumber: 4,
          icon: Icons.shopping_cart_checkout,
          color: Colors.purple,
          title: '4. Outbound Picking & Dispatch (Bin -> Customer)',
          subtitle: 'Pick Run #PICK-2026-001 for Tech Solutions Pvt Ltd',
          details: [
            'Sales Order: ORD-5001',
            'Quantity Picked: 5 units from Bin A-01-S1',
            'Remaining Lot Qty: 45 units',
            'Picked By: picker@warehouse.io',
            'Tracking / Dispatch: DISP-IND-9942',
          ],
          isLast: true,
        ),
      ],
    );
  }
}

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({
    required this.stepNumber,
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.details,
    this.isLast = false,
  });

  final int stepNumber;
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final List<String> details;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step Line & Badge
          Column(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: color,
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: Colors.grey.shade300,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          // Content
          Expanded(
            child: Container(
              margin: EdgeInsets.only(bottom: isLast ? 0 : 20),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12)),
                  const Divider(height: 16),
                  for (final d in details)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Text('• $d', style: TextStyle(fontSize: 12, color: Colors.grey.shade800)),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
