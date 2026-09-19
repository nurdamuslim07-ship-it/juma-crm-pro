import 'package:flutter_test/flutter_test.dart';
import 'package:juma_ui_crm/features/purchases/domain/value_objects/quantity.dart';

void main() {
  test('throws for a zero or negative value', () {
    expect(() => Quantity(0), throwsArgumentError);
    expect(() => Quantity(-5), throwsArgumentError);
  });

  test('accepts a fractional positive value', () {
    expect(Quantity(2.5).value, 2.5);
  });

  test('addition combines values', () {
    expect(Quantity(2) + Quantity(3), Quantity(5));
  });

  test('comparison operators order by value', () {
    expect(Quantity(5) > Quantity(3), isTrue);
    expect(Quantity(3) < Quantity(5), isTrue);
    expect(Quantity(5) >= Quantity(5), isTrue);
    expect(Quantity(5) <= Quantity(5), isTrue);
  });

  test('equality and hashCode are based on value', () {
    expect(Quantity(5), Quantity(5));
    expect(Quantity(5).hashCode, Quantity(5).hashCode);
  });
}
