import 'package:flutter/foundation.dart';

/// Mirrors a row of the `production_stages` table — deliberately a
/// database-driven list, not a hardcoded Dart enum, per that table's
/// existing "status percentages should be configurable" design (see
/// supabase/migrations/20260713000005_orders.sql). The owner's exact
/// 9-stage shop-floor Kanban is what's seeded today (see
/// supabase/seed/seed.sql), but this entity makes no assumption about
/// the count or specific keys.
@immutable
class ProductionStage {
  const ProductionStage({
    required this.id,
    required this.key,
    required this.nameKk,
    required this.sortOrder,
    required this.defaultPercent,
  });

  final String id;
  final String key;
  final String nameKk;
  final int sortOrder;
  final int defaultPercent;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductionStage &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
