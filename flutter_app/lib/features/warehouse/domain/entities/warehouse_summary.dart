import 'package:flutter/foundation.dart';

/// Requirement: "Қойма аналитикасы" — backed by `get_warehouse_summary()`.
@immutable
class WarehouseSummary {
  const WarehouseSummary({
    required this.materialsCount,
    required this.lowStockCount,
    required this.totalInventoryValueTiyn,
    required this.categoryBreakdown,
  });

  final int materialsCount;
  final int lowStockCount;
  final int totalInventoryValueTiyn;

  /// Category name (kk) -> material count.
  final Map<String, int> categoryBreakdown;
}
