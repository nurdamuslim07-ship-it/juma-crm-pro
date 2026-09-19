import '../../domain/entities/production_queue_item.dart';

class ProductionQueueItemModel extends ProductionQueueItem {
  const ProductionQueueItemModel({
    required super.orderId,
    required super.orderNumber,
    required super.productType,
    required super.clientName,
    required super.stageId,
    required super.stageKey,
    required super.stageNameKk,
    required super.stageSortOrder,
    required super.percentComplete,
    super.masterId,
    super.masterName,
    required super.materialsSufficient,
    required super.photosCount,
    super.plannedCompletionDate,
    required super.updatedAt,
  });

  /// Parses one row of `get_production_queue()`'s result set — see
  /// that RPC's doc comment in
  /// supabase/migrations/20260713000020_production_module.sql.
  factory ProductionQueueItemModel.fromRow(Map<String, dynamic> row) {
    return ProductionQueueItemModel(
      orderId: row['order_id'] as String,
      orderNumber: (row['order_number'] as String?) ?? '',
      productType: (row['product_type'] as String?) ?? '',
      clientName: (row['client_name'] as String?) ?? '',
      stageId: row['stage_id'] as String,
      stageKey: (row['stage_key'] as String?) ?? '',
      stageNameKk: (row['stage_name_kk'] as String?) ?? '',
      stageSortOrder: (row['stage_sort_order'] as num?)?.toInt() ?? 0,
      percentComplete: (row['percent_complete'] as num?)?.toInt() ?? 0,
      masterId: row['master_id'] as String?,
      masterName: row['master_name'] as String?,
      materialsSufficient: (row['materials_sufficient'] as bool?) ?? true,
      photosCount: (row['photos_count'] as num?)?.toInt() ?? 0,
      plannedCompletionDate: row['planned_completion_date'] != null
          ? DateTime.parse(row['planned_completion_date'] as String)
          : null,
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }
}
