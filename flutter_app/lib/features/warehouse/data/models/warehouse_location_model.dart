import '../../domain/entities/warehouse_location.dart';

class WarehouseLocationModel extends WarehouseLocation {
  const WarehouseLocationModel({
    required super.id,
    required super.warehouseId,
    required super.name,
  });

  factory WarehouseLocationModel.fromRow(Map<String, dynamic> row) {
    return WarehouseLocationModel(
      id: row['id'] as String,
      warehouseId: row['warehouse_id'] as String,
      name: (row['name'] as String?) ?? '',
    );
  }
}
