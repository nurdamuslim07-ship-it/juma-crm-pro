import 'package:flutter/foundation.dart';

/// One entry in the master-assignment picker — see `get_masters()` in
/// supabase/migrations/20260713000020_production_module.sql.
/// Deliberately just an id/name pair, not the full Employee entity —
/// this picker has no business showing salary/contact fields.
@immutable
class ProductionMaster {
  const ProductionMaster({required this.userId, required this.fullName});

  final String userId;
  final String fullName;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductionMaster &&
          runtimeType == other.runtimeType &&
          userId == other.userId;

  @override
  int get hashCode => userId.hashCode;
}
