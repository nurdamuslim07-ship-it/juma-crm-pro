import 'package:flutter/foundation.dart';

/// Requirement: "Уақыт журналдары" — every entry (including other
/// employees' logs) carries its `id`, so an already-open timer is
/// still stoppable after a reload/re-navigation, not just right after
/// `startTimeLog()` returns it; `stopTimeLog()`'s own RLS/permission
/// check (own row, or director/workshop_manager) is what actually
/// decides who may act on which id — this entity has no restriction.
@immutable
class ProductionTimeLog {
  const ProductionTimeLog({
    this.id,
    required this.employeeId,
    required this.employeeName,
    this.stageNameKk,
    required this.startedAt,
    this.endedAt,
  });

  final String? id;
  final String employeeId;
  final String employeeName;
  final String? stageNameKk;
  final DateTime startedAt;
  final DateTime? endedAt;

  bool get isOpen => endedAt == null;
}
