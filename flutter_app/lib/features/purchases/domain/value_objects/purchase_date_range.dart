import 'package:flutter/foundation.dart';

/// An inclusive `[from, to]` date span. Not yet wired to any RPC —
/// `get_purchase_analytics()` currently takes no date-range parameter
/// (see supabase/migrations/20260713000022_purchases_module.sql; it
/// always reports "this month" for monthly purchases). Provided as a
/// ready-made, independently testable primitive for a future
/// date-filterable analytics view.
@immutable
class PurchaseDateRange {
  factory PurchaseDateRange({required DateTime from, required DateTime to}) {
    if (to.isBefore(from)) {
      throw ArgumentError.value(
        to,
        'to',
        'Аяқталу күні басталу күнінен ерте болмауы керек',
      );
    }
    return PurchaseDateRange._(from: from, to: to);
  }

  const PurchaseDateRange._({required this.from, required this.to});

  final DateTime from;
  final DateTime to;

  bool contains(DateTime date) => !date.isBefore(from) && !date.isAfter(to);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PurchaseDateRange &&
          runtimeType == other.runtimeType &&
          from == other.from &&
          to == other.to;

  @override
  int get hashCode => Object.hash(from, to);
}
