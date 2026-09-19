import '../../domain/entities/warehouse_summary.dart';

class WarehouseSummaryModel extends WarehouseSummary {
  const WarehouseSummaryModel({
    required super.materialsCount,
    required super.lowStockCount,
    required super.totalInventoryValueTiyn,
    required super.categoryBreakdown,
  });

  factory WarehouseSummaryModel.fromRow(Map<String, dynamic> row) {
    final breakdown = row['category_breakdown'] as Map<String, dynamic>? ?? {};
    return WarehouseSummaryModel(
      materialsCount: (row['materials_count'] as num?)?.toInt() ?? 0,
      lowStockCount: (row['low_stock_count'] as num?)?.toInt() ?? 0,
      totalInventoryValueTiyn:
          (row['total_inventory_value_tiyn'] as num?)?.toInt() ?? 0,
      categoryBreakdown: breakdown.map(
        (key, value) => MapEntry(key, (value as num).toInt()),
      ),
    );
  }
}
