import 'package:flutter_test/flutter_test.dart';
import 'package:juma_ui_crm/features/purchases/domain/value_objects/purchase_date_range.dart';

void main() {
  test('throws when "to" is before "from"', () {
    expect(
      () => PurchaseDateRange(
        from: DateTime(2026, 7, 13),
        to: DateTime(2026, 7, 1),
      ),
      throwsArgumentError,
    );
  });

  test('accepts an equal from/to as a single-day range', () {
    final range = PurchaseDateRange(
      from: DateTime(2026, 7, 13),
      to: DateTime(2026, 7, 13),
    );
    expect(range.from, range.to);
  });

  test('contains is inclusive of both endpoints', () {
    final range = PurchaseDateRange(
      from: DateTime(2026, 7, 1),
      to: DateTime(2026, 7, 31),
    );
    expect(range.contains(DateTime(2026, 7, 1)), isTrue);
    expect(range.contains(DateTime(2026, 7, 31)), isTrue);
    expect(range.contains(DateTime(2026, 7, 15)), isTrue);
    expect(range.contains(DateTime(2026, 6, 30)), isFalse);
    expect(range.contains(DateTime(2026, 8, 1)), isFalse);
  });

  test('equality and hashCode are based on from and to', () {
    final a = PurchaseDateRange(
      from: DateTime(2026, 7, 1),
      to: DateTime(2026, 7, 31),
    );
    final b = PurchaseDateRange(
      from: DateTime(2026, 7, 1),
      to: DateTime(2026, 7, 31),
    );
    expect(a, b);
    expect(a.hashCode, b.hashCode);
  });
}
