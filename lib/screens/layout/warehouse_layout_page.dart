import 'package:flutter/material.dart';
import 'package:warehouse_management/core/app_scope.dart';
import 'package:warehouse_management/models/product.dart';
import 'package:warehouse_management/models/warehouse_zone.dart';
import 'package:warehouse_management/services/enterprise_store.dart';
import 'package:warehouse_management/utils/color_palette.dart';

class WarehouseLayoutPage extends StatefulWidget {
  const WarehouseLayoutPage({super.key});

  @override
  State<WarehouseLayoutPage> createState() => _WarehouseLayoutPageState();
}

class _WarehouseLayoutPageState extends State<WarehouseLayoutPage> {
  final _store = EnterpriseStore.instance;
  int _selectedZoneIndex = 0;
  String _binSearch = '';

  @override
  Widget build(BuildContext context) {
    final zones = _store.zones;
    if (zones.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Warehouse Zones & Layout')),
        body: const Center(child: Text('No warehouse zones configured.')),
      );
    }

    final currentZone = zones[_selectedZoneIndex];
    final utilizationPct = (currentZone.utilizationRate * 100).toInt();

    final filteredBins = currentZone.bins.where((b) {
      if (_binSearch.isEmpty) return true;
      final q = _binSearch.toLowerCase();
      return b.binCode.toLowerCase().contains(q) ||
          b.aisle.toLowerCase().contains(q) ||
          b.primaryCategory.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: ColorPalette.aquaHaze,
      appBar: AppBar(
        title: const Text('Warehouse Zones & Bin Layout'),
      ),
      body: Column(
        children: [
          // Zone Selector Cards
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(zones.length, (i) {
                  final z = zones[i];
                  final isSelected = i == _selectedZoneIndex;
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => setState(() => _selectedZoneIndex = i),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? ColorPalette.pacificBlue.withValues(alpha: 0.15)
                              : ColorPalette.aquaHaze,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? ColorPalette.pacificBlue
                                : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.warehouse_outlined,
                              color: isSelected
                                  ? ColorPalette.pacificBlue
                                  : Colors.grey.shade700,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  z.zoneCode,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: isSelected
                                        ? ColorPalette.timberGreen
                                        : Colors.black87,
                                  ),
                                ),
                                Text(
                                  '${(z.utilizationRate * 100).toInt()}% Occupied',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
          const Divider(height: 1),
          // Active Zone Overview Banner
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${currentZone.zoneCode}: ${currentZone.name}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: ColorPalette.timberGreen,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            currentZone.type,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.thermostat,
                              size: 16, color: Colors.blue),
                          const SizedBox(width: 4),
                          Text(
                            '${currentZone.temperatureC}°C',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Capacity: ${currentZone.occupiedCapacity} / ${currentZone.totalCapacity} units',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                    ),
                    Text(
                      '$utilizationPct% Utilized',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: ColorPalette.timberGreen,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: currentZone.utilizationRate,
                    minHeight: 8,
                    backgroundColor: Colors.grey.shade200,
                    color: utilizationPct > 85
                        ? Colors.red
                        : utilizationPct > 65
                            ? Colors.orange
                            : ColorPalette.pacificBlue,
                  ),
                ),
              ],
            ),
          ),
          // Search Bin Code
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search bin code, aisle (e.g. A-01-01)...',
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                suffixIcon: _binSearch.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => _binSearch = ''),
                      )
                    : null,
              ),
              onChanged: (v) => setState(() => _binSearch = v),
            ),
          ),
          const SizedBox(height: 12),
          // Interactive Bin Grid
          Expanded(
            child: LayoutBuilder(
              builder: (ctx, constraints) {
                final crossAxisCount = constraints.maxWidth > 900
                    ? 4
                    : constraints.maxWidth > 600
                        ? 3
                        : 2;

                return GridView.builder(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 4),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.25,
                  ),
                  itemCount: filteredBins.length,
                  itemBuilder: (ctx, idx) => _buildBinTile(
                    context,
                    filteredBins[idx],
                    currentZone,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBinTile(
    BuildContext context,
    WarehouseBin bin,
    WarehouseZone zone,
  ) {
    final pct = (bin.utilization * 100).toInt();
    Color statusColor;
    if (bin.isFull) {
      statusColor = Colors.red;
    } else if (pct > 80) {
      statusColor = Colors.orange;
    } else if (pct > 40) {
      statusColor = ColorPalette.pacificBlue;
    } else {
      statusColor = Colors.green;
    }

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => _showBinDetailModal(context, bin, zone),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: statusColor.withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  bin.binCode,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: ColorPalette.timberGreen,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '$pct%',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            Text(
              '${bin.aisle} • ${bin.shelf}',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
            Text(
              bin.primaryCategory,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade800,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: bin.utilization,
                    minHeight: 5,
                    backgroundColor: Colors.grey.shade100,
                    color: statusColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${bin.occupiedUnits} / ${bin.capacity} units',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showBinDetailModal(
    BuildContext context,
    WarehouseBin bin,
    WarehouseZone zone,
  ) {
    final scope = AppScope.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StreamBuilder<List<ProductItem>>(
        stream: scope.repo.watchProducts(),
        builder: (ctx, snap) {
          final products = snap.data ?? [];
          // Products matching bin or zone
          final matchedProducts = products.where((p) {
            final loc = p.product.location.toLowerCase();
            return loc.contains(bin.binCode.toLowerCase()) ||
                loc.contains(zone.zoneCode.toLowerCase());
          }).toList();

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bin ${bin.binCode}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: ColorPalette.timberGreen,
                          ),
                        ),
                        Text(
                          '${zone.zoneCode} • ${bin.aisle} • ${bin.shelf}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _buildModalStat(
                        'Occupancy',
                        '${bin.occupiedUnits} units',
                        Icons.layers_outlined,
                      ),
                    ),
                    Expanded(
                      child: _buildModalStat(
                        'Total Capacity',
                        '${bin.capacity} units',
                        Icons.straighten_outlined,
                      ),
                    ),
                    Expanded(
                      child: _buildModalStat(
                        'Category',
                        bin.primaryCategory,
                        Icons.category_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Products Mapped to this Location:',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (matchedProducts.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: ColorPalette.aquaHaze,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'No specific products mapped to "${bin.binCode}". Space is available for incoming stock.',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                    ),
                  )
                else
                  ...matchedProducts.map((p) => ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const CircleAvatar(
                          radius: 16,
                          backgroundColor: ColorPalette.pacificBlue,
                          child: Icon(Icons.inventory,
                              size: 16, color: Colors.white),
                        ),
                        title: Text(p.product.name,
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.bold)),
                        subtitle: Text(
                            'SKU: ${p.product.sku} • Location: ${p.product.location}'),
                        trailing: Text(
                          '${p.product.quantity} pcs',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      )),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildModalStat(String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: ColorPalette.aquaHaze,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: ColorPalette.pacificBlue),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
