class WarehouseBin {
  const WarehouseBin({
    required this.binCode, // e.g. A-01-1
    required this.aisle,   // A-01
    required this.shelf,   // S-1
    required this.capacity,
    this.occupiedUnits = 0,
    this.primaryCategory = '',
  });

  final String binCode;
  final String aisle;
  final String shelf;
  final int capacity;
  final int occupiedUnits;
  final String primaryCategory;

  double get utilization => capacity == 0 ? 0.0 : (occupiedUnits / capacity).clamp(0.0, 1.0);
  bool get isFull => occupiedUnits >= capacity;
}

class WarehouseZone {
  const WarehouseZone({
    required this.zoneCode, // e.g. Zone A
    required this.name,     // High-Density Electronics
    required this.type,     // Temperature Controlled, Bulk Pallet, Small Parts
    required this.totalCapacity,
    required this.occupiedCapacity,
    required this.temperatureC,
    required this.bins,
  });

  final String zoneCode;
  final String name;
  final String type;
  final int totalCapacity;
  final int occupiedCapacity;
  final double temperatureC;
  final List<WarehouseBin> bins;

  double get utilizationRate =>
      totalCapacity == 0 ? 0.0 : (occupiedCapacity / totalCapacity).clamp(0.0, 1.0);
}
