import 'package:flutter/foundation.dart';

/// One order on the shop-floor Kanban/queue — see `get_production_queue()`
/// in supabase/migrations/20260713000020_production_module.sql. Only
/// ever contains orders the caller is allowed to see (director/manager/
/// workshop_manager see every order in production; anyone else with
/// just `production.read` sees only their assigned orders) — this
/// entity never needs its own visibility flags, unlike Partner/
/// AnalyticsSummary, because the RPC either includes a row or omits it
/// entirely rather than partially redacting one.
@immutable
class ProductionQueueItem {
  const ProductionQueueItem({
    required this.orderId,
    required this.orderNumber,
    required this.productType,
    required this.clientName,
    required this.stageId,
    required this.stageKey,
    required this.stageNameKk,
    required this.stageSortOrder,
    required this.percentComplete,
    this.masterId,
    this.masterName,
    required this.materialsSufficient,
    required this.photosCount,
    this.plannedCompletionDate,
    required this.updatedAt,
  });

  final String orderId;
  final String orderNumber;
  final String productType;
  final String clientName;
  final String stageId;
  final String stageKey;
  final String stageNameKk;
  final int stageSortOrder;
  final int percentComplete;
  final String? masterId;
  final String? masterName;
  final bool materialsSufficient;
  final int photosCount;
  final DateTime? plannedCompletionDate;
  final DateTime updatedAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductionQueueItem &&
          runtimeType == other.runtimeType &&
          orderId == other.orderId;

  @override
  int get hashCode => orderId.hashCode;
}
