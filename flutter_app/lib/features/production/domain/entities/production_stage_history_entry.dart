import 'package:flutter/foundation.dart';

/// Requirement: "Өндіріс тарихы" — one row per real stage transition,
/// written only by the `enforce_production_stage_change` trigger (see
/// supabase/migrations/20260713000020_production_module.sql), never
/// directly by the app.
@immutable
class ProductionStageHistoryEntry {
  const ProductionStageHistoryEntry({
    this.previousStageName,
    required this.newStageName,
    this.changedByName,
    required this.changedAt,
    this.comment,
  });

  final String? previousStageName;
  final String newStageName;
  final String? changedByName;
  final DateTime changedAt;
  final String? comment;
}
