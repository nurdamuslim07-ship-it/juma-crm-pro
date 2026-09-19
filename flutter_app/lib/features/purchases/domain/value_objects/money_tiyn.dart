import 'package:flutter/foundation.dart';

/// A non-negative money amount in integer minor units (tiyn), per
/// CLAUDE.md's "money is stored as integer minor units, never floating
/// point" rule. Existing entities (PurchaseOrderDetail, PurchaseOrderItem,
/// etc.) keep plain `int ...Tiyn` fields for backward compatibility with
/// already-committed presentation code — this type is for new code
/// (validation, [SupplierBalance] math) that wants a value genuinely
/// guaranteed non-negative by construction, rather than trusting every
/// call site to check.
@immutable
class MoneyTiyn {
  factory MoneyTiyn(int amountTiyn) {
    if (amountTiyn < 0) {
      throw ArgumentError.value(
        amountTiyn,
        'amountTiyn',
        'Ақша сомасы теріс болмауы керек',
      );
    }
    return MoneyTiyn._(amountTiyn);
  }

  const MoneyTiyn._(this.amountTiyn);

  static const zero = MoneyTiyn._(0);

  final int amountTiyn;

  double get tenge => amountTiyn / 100;

  /// e.g. "17 000 ₸" — matches the plain `(amountTiyn / 100).toStringAsFixed(0)`
  /// formatting already used throughout the Purchases screens.
  String formatTenge() => '${tenge.toStringAsFixed(0)} ₸';

  MoneyTiyn operator +(MoneyTiyn other) =>
      MoneyTiyn(amountTiyn + other.amountTiyn);

  MoneyTiyn operator -(MoneyTiyn other) =>
      MoneyTiyn(amountTiyn - other.amountTiyn);

  bool operator >(MoneyTiyn other) => amountTiyn > other.amountTiyn;

  bool operator >=(MoneyTiyn other) => amountTiyn >= other.amountTiyn;

  bool operator <(MoneyTiyn other) => amountTiyn < other.amountTiyn;

  bool operator <=(MoneyTiyn other) => amountTiyn <= other.amountTiyn;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MoneyTiyn &&
          runtimeType == other.runtimeType &&
          amountTiyn == other.amountTiyn;

  @override
  int get hashCode => amountTiyn.hashCode;

  @override
  String toString() => formatTenge();
}
