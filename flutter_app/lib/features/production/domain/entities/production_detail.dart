import 'package:flutter/foundation.dart';

import 'material_availability.dart';
import 'production_photo.dart';
import 'production_stage_history_entry.dart';
import 'production_time_log.dart';

/// See `get_order_production_detail()` in
/// supabase/migrations/20260713000020_production_module.sql.
@immutable
class ProductionDetail {
  const ProductionDetail({
    required this.orderId,
    required this.orderNumber,
    required this.productType,
    required this.clientName,
    this.address,
    this.plannedCompletionDate,
    required this.stageId,
    required this.stageKey,
    required this.stageNameKk,
    required this.percentComplete,
    this.masterId,
    this.masterName,
    this.materials = const [],
    this.recentPhotos = const [],
    this.timeLogs = const [],
    this.stageHistory = const [],
  });

  final String orderId;
  final String orderNumber;
  final String productType;
  final String clientName;
  final String? address;
  final DateTime? plannedCompletionDate;
  final String stageId;
  final String stageKey;
  final String stageNameKk;
  final int percentComplete;
  final String? masterId;
  final String? masterName;
  final List<MaterialAvailability> materials;
  final List<ProductionPhoto> recentPhotos;
  final List<ProductionTimeLog> timeLogs;
  final List<ProductionStageHistoryEntry> stageHistory;

  bool get allMaterialsSufficient => materials.every((m) => m.isSufficient);
}
