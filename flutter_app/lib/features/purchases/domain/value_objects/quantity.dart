import 'package:flutter/foundation.dart';

/// A strictly positive material quantity — mirrors the
/// `check (quantity > 0)` constraint on `purchase_order_items` in
/// supabase/migrations/20260713000022_purchases_module.sql. Quantities
/// stay plain `num` on the existing entities for backward
/// compatibility; this type is for new validation/domain code that
/// wants that constraint enforced by construction.
@immutable
class Quantity {
  factory Quantity(num value) {
    if (value <= 0) {
      throw ArgumentError.value(
        value,
        'value',
        'Мөлшер 0-ден үлкен болуы керек',
      );
    }
    return Quantity._(value);
  }

  const Quantity._(this.value);

  final num value;

  Quantity operator +(Quantity other) => Quantity(value + other.value);

  bool operator >(Quantity other) => value > other.value;

  bool operator >=(Quantity other) => value >= other.value;

  bool operator <(Quantity other) => value < other.value;

  bool operator <=(Quantity other) => value <= other.value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Quantity &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value.toString();
}
