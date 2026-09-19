import '../../domain/entities/material_availability.dart';
import '../../domain/entities/production_detail.dart';
import '../../domain/entities/production_photo.dart';
import '../../domain/entities/production_stage_history_entry.dart';
import '../../domain/entities/production_time_log.dart';

class ProductionDetailModel extends ProductionDetail {
  const ProductionDetailModel({
    required super.orderId,
    required super.orderNumber,
    required super.productType,
    required super.clientName,
    super.address,
    super.plannedCompletionDate,
    required super.stageId,
    required super.stageKey,
    required super.stageNameKk,
    required super.percentComplete,
    super.masterId,
    super.masterName,
    super.materials,
    super.recentPhotos,
    super.timeLogs,
    super.stageHistory,
  });

  /// Parses `get_order_production_detail()`'s single-row result — see
  /// that RPC's doc comment in
  /// supabase/migrations/20260713000020_production_module.sql.
  factory ProductionDetailModel.fromRow(Map<String, dynamic> row) {
    return ProductionDetailModel(
      orderId: row['order_id'] as String,
      orderNumber: (row['order_number'] as String?) ?? '',
      productType: (row['product_type'] as String?) ?? '',
      clientName: (row['client_name'] as String?) ?? '',
      address: row['address'] as String?,
      plannedCompletionDate: row['planned_completion_date'] != null
          ? DateTime.parse(row['planned_completion_date'] as String)
          : null,
      stageId: row['stage_id'] as String,
      stageKey: (row['stage_key'] as String?) ?? '',
      stageNameKk: (row['stage_name_kk'] as String?) ?? '',
      percentComplete: (row['percent_complete'] as num?)?.toInt() ?? 0,
      masterId: row['master_id'] as String?,
      masterName: row['master_name'] as String?,
      materials: _parseMaterials(row['materials']),
      recentPhotos: _parsePhotos(row['recent_photos']),
      timeLogs: _parseTimeLogs(row['time_logs']),
      stageHistory: _parseStageHistory(row['stage_history']),
    );
  }

  static List<MaterialAvailability> _parseMaterials(dynamic value) {
    if (value is! List) return const [];
    return value
        .cast<Map<String, dynamic>>()
        .map(
          (m) => MaterialAvailability(
            materialId: m['material_id'] as String?,
            materialName: (m['material_name'] as String?) ?? '',
            unit: (m['unit'] as String?) ?? '',
            reservedQuantity: (m['reserved_quantity'] as num?)?.toDouble() ?? 0,
            availableQuantity:
                (m['available_quantity'] as num?)?.toDouble() ?? 0,
            isSufficient: (m['is_sufficient'] as bool?) ?? true,
          ),
        )
        .toList();
  }

  static List<ProductionPhoto> _parsePhotos(dynamic value) {
    if (value is! List) return const [];
    return value
        .cast<Map<String, dynamic>>()
        .map(
          (p) => ProductionPhoto(
            id: p['id'] as String,
            storagePath: (p['storage_path'] as String?) ?? '',
            uploadedAt: DateTime.parse(p['uploaded_at'] as String),
          ),
        )
        .toList();
  }

  static List<ProductionTimeLog> _parseTimeLogs(dynamic value) {
    if (value is! List) return const [];
    return value
        .cast<Map<String, dynamic>>()
        .map(
          (t) => ProductionTimeLog(
            id: t['id'] as String?,
            employeeId: (t['employee_id'] as String?) ?? '',
            employeeName: (t['employee_name'] as String?) ?? '',
            stageNameKk: t['stage_name_kk'] as String?,
            startedAt: DateTime.parse(t['started_at'] as String),
            endedAt: t['ended_at'] != null
                ? DateTime.parse(t['ended_at'] as String)
                : null,
          ),
        )
        .toList();
  }

  static List<ProductionStageHistoryEntry> _parseStageHistory(dynamic value) {
    if (value is! List) return const [];
    return value
        .cast<Map<String, dynamic>>()
        .map(
          (h) => ProductionStageHistoryEntry(
            previousStageName: h['previous_stage_name'] as String?,
            newStageName: (h['new_stage_name'] as String?) ?? '',
            changedByName: h['changed_by_name'] as String?,
            changedAt: DateTime.parse(h['changed_at'] as String),
            comment: h['comment'] as String?,
          ),
        )
        .toList();
  }
}
