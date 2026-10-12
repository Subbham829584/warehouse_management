import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:warehouse_management/core/ui.dart';
import 'package:warehouse_management/models/warehouse_equipment.dart';
import 'package:warehouse_management/services/enterprise_store.dart';
import 'package:warehouse_management/utils/color_palette.dart';

class EquipmentPage extends StatefulWidget {
  const EquipmentPage({super.key});

  @override
  State<EquipmentPage> createState() => _EquipmentPageState();
}

class _EquipmentPageState extends State<EquipmentPage> {
  final _store = EnterpriseStore.instance;

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
    final equipment = _store.equipment;
    final operationalCount = equipment
        .where((e) => e.status == EquipmentStatus.operational)
        .length;
    final maintenanceDueCount = equipment
        .where((e) => e.status == EquipmentStatus.maintenanceDue)
        .length;
    final totalHours =
        equipment.fold(0, (acc, e) => acc + e.operatingHours);

    return Scaffold(
      backgroundColor: ColorPalette.aquaHaze,
      appBar: AppBar(
        title: const Text('Equipment & Machinery Tracker'),
      ),
      body: Column(
        children: [
          // KPI Metric Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: Row(
              children: [
                _buildKpi(
                  'Operational',
                  '$operationalCount',
                  Icons.check_circle_outline,
                  Colors.green.shade700,
                ),
                const SizedBox(width: 8),
                _buildKpi(
                  'Maintenance Due',
                  '$maintenanceDueCount',
                  Icons.build_circle_outlined,
                  Colors.orange.shade800,
                ),
                const SizedBox(width: 8),
                _buildKpi(
                  'Total Fleet Hours',
                  '${NumberFormat.compact().format(totalHours)} hrs',
                  Icons.timer_outlined,
                  ColorPalette.pacificBlue,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Equipment List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: equipment.length,
              itemBuilder: (ctx, i) =>
                  _buildEquipmentCard(context, equipment[i], currency),
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

  Widget _buildEquipmentCard(
    BuildContext context,
    WarehouseEquipment eq,
    NumberFormat currency,
  ) {
    Color statusColor;
    String statusText;
    switch (eq.status) {
      case EquipmentStatus.operational:
        statusColor = Colors.green;
        statusText = 'Operational';
        break;
      case EquipmentStatus.maintenanceDue:
        statusColor = Colors.orange;
        statusText = 'Service Due';
        break;
      case EquipmentStatus.outOfService:
        statusColor = Colors.red;
        statusText = 'Out of Service';
        break;
    }

    IconData typeIcon;
    switch (eq.type) {
      case EquipmentType.forklift:
        typeIcon = Icons.forklift;
        break;
      case EquipmentType.palletJack:
        typeIcon = Icons.inventory;
        break;
      case EquipmentType.barcodeScanner:
        typeIcon = Icons.qr_code_scanner;
        break;
      case EquipmentType.labelPrinter:
        typeIcon = Icons.print;
        break;
      case EquipmentType.coldStorage:
        typeIcon = Icons.ac_unit;
        break;
    }

    final dateFormat = DateFormat('MMM d, yyyy');

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
                    color: ColorPalette.nileBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(typeIcon, color: ColorPalette.nileBlue, size: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              eq.assetTag,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 11),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              eq.name,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: ColorPalette.timberGreen,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Location: ${eq.assignedZone}',
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
            // Battery & Hours Bar
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Battery / Power:',
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey.shade600)),
                          Text('${eq.batteryLevelPct}%',
                              style: const TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: eq.batteryLevelPct / 100,
                          minHeight: 6,
                          backgroundColor: Colors.grey.shade200,
                          color: eq.batteryLevelPct > 30
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Total Run Hours',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade600)),
                    Text('${eq.operatingHours} hrs',
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.bold)),
                  ],
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
                  Text(
                    'Last Service: ${dateFormat.format(eq.lastServiceDate)}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                  ),
                  Text(
                    'Next Due: ${dateFormat.format(eq.nextServiceDate)}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: eq.nextServiceDate.isBefore(DateTime.now())
                          ? Colors.red
                          : Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
            ),
            if (eq.serviceLogs.isNotEmpty) ...[
              const SizedBox(height: 8),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                dense: true,
                title: Text(
                  'Service History (${eq.serviceLogs.length} records)',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                children: eq.serviceLogs.map((log) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${dateFormat.format(log.date)}: ${log.description} (${log.technician})',
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                      Text(currency.format(log.cost),
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                )).toList(),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showLogServiceDialog(context, eq),
                    icon: const Icon(Icons.build, size: 16),
                    label: const Text('Log Maintenance Service'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showLogServiceDialog(BuildContext context, WarehouseEquipment eq) {
    final techCtrl = TextEditingController(text: 'Marcus Vance');
    final descCtrl = TextEditingController(text: 'Routine safety check & calibration');
    final costCtrl = TextEditingController(text: '120.00');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Service Log: ${eq.assetTag} (${eq.name})'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: techCtrl,
                decoration: const InputDecoration(labelText: 'Technician Name'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: 'Service Notes / Scope'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: costCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Service Cost (\$)', prefixText: '\$'),
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
            style: FilledButton.styleFrom(backgroundColor: ColorPalette.pacificBlue),
            onPressed: () {
              final cost = double.tryParse(costCtrl.text.trim()) ?? 0.0;
              _store.logEquipmentService(
                equipmentId: eq.id,
                technician: techCtrl.text.trim(),
                description: descCtrl.text.trim(),
                cost: cost,
                nextDueDate: DateTime.now().add(const Duration(days: 90)),
              );
              Navigator.pop(ctx);
              showMessage(context, 'Maintenance record logged for ${eq.assetTag}!');
            },
            child: const Text('Save & Certify'),
          ),
        ],
      ),
    );
  }
}
