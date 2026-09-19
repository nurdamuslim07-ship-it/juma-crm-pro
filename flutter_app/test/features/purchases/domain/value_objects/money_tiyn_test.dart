import 'package:flutter_test/flutter_test.dart';
import 'package:juma_ui_crm/features/purchases/domain/value_objects/money_tiyn.dart';

void main() {
  test('throws for a negative amount', () {
    expect(() => MoneyTiyn(-1), throwsArgumentError);
  });

  test('zero is a valid non-negative amount', () {
    expect(MoneyTiyn.zero.amountTiyn, 0);
    expect(MoneyTiyn(0), MoneyTiyn.zero);
  });

  test('tenge converts minor units to major units', () {
    expect(MoneyTiyn(17000000).tenge, 170000);
  });

  test('formatTenge renders whole tenge with the currency sign', () {
    expect(MoneyTiyn(17000000).formatTenge(), '170000 ₸');
  });

  test('arithmetic operators combine amounts', () {
    expect(MoneyTiyn(500) + MoneyTiyn(300), MoneyTiyn(800));
    expect(MoneyTiyn(500) - MoneyTiyn(300), MoneyTiyn(200));
  });

  test('subtraction below zero throws', () {
    expect(() => MoneyTiyn(100) - MoneyTiyn(200), throwsArgumentError);
  });

  test('comparison operators order by amount', () {
    expect(MoneyTiyn(500) > MoneyTiyn(300), isTrue);
    expect(MoneyTiyn(300) < MoneyTiyn(500), isTrue);
    expect(MoneyTiyn(500) >= MoneyTiyn(500), isTrue);
    expect(MoneyTiyn(500) <= MoneyTiyn(500), isTrue);
  });

  test('equality and hashCode are based on amountTiyn', () {
    expect(MoneyTiyn(500), MoneyTiyn(500));
    expect(MoneyTiyn(500).hashCode, MoneyTiyn(500).hashCode);
  });
}
