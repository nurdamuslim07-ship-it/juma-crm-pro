import 'package:flutter/foundation.dart';

/// A non-empty, trimmed purchase order number (`purchase_orders.order_number`
/// — `not null unique` in the SQL). The existing `PurchaseOrderSummary`/
/// `PurchaseOrderDetail` entities keep a plain `String orderNumber` for
/// backward compatibility; this type is for new code (form validation)
/// that wants "non-empty" guaranteed by construction.
@immutable
class PurchaseNumber {
  factory PurchaseNumber(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(
        value,
        'value',
        'Тапсырыс нөмірі бос болмауы керек',
      );
    }
    return PurchaseNumber._(trimmed);
  }

  const PurchaseNumber._(this.value);

  final String value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PurchaseNumber &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}
