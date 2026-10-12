enum EquipmentStatus { operational, maintenanceDue, outOfService }

enum EquipmentType { forklift, palletJack, barcodeScanner, labelPrinter, coldStorage }

class EquipmentServiceLog {
  const EquipmentServiceLog({
    required this.id,
    required this.date,
    required this.technician,
    required this.description,
    required this.cost,
  });

  final String id;
  final DateTime date;
  final String technician;
  final String description;
  final double cost;
}

class WarehouseEquipment {
  const WarehouseEquipment({
    required this.id,
    required this.assetTag, // e.g. FL-01
    required this.name,     // Toyota 8FBE15 Electric Forklift
    required this.type,
    required this.assignedZone,
    this.status = EquipmentStatus.operational,
    this.operatingHours = 0,
    this.batteryLevelPct = 100,
    required this.lastServiceDate,
    required this.nextServiceDate,
    this.serviceLogs = const [],
  });

  final String id;
  final String assetTag;
  final String name;
  final EquipmentType type;
  final String assignedZone;
  final EquipmentStatus status;
  final int operatingHours;
  final int batteryLevelPct;
  final DateTime lastServiceDate;
  final DateTime nextServiceDate;
  final List<EquipmentServiceLog> serviceLogs;

  WarehouseEquipment copyWith({
    String? id,
    String? assetTag,
    String? name,
    EquipmentType? type,
    String? assignedZone,
    EquipmentStatus? status,
    int? operatingHours,
    int? batteryLevelPct,
    DateTime? lastServiceDate,
    DateTime? nextServiceDate,
    List<EquipmentServiceLog>? serviceLogs,
  }) {
    return WarehouseEquipment(
      id: id ?? this.id,
      assetTag: assetTag ?? this.assetTag,
      name: name ?? this.name,
      type: type ?? this.type,
      assignedZone: assignedZone ?? this.assignedZone,
      status: status ?? this.status,
      operatingHours: operatingHours ?? this.operatingHours,
      batteryLevelPct: batteryLevelPct ?? this.batteryLevelPct,
      lastServiceDate: lastServiceDate ?? this.lastServiceDate,
      nextServiceDate: nextServiceDate ?? this.nextServiceDate,
      serviceLogs: serviceLogs ?? this.serviceLogs,
    );
  }
}
