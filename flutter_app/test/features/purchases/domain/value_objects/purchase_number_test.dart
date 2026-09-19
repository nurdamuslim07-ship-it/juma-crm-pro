import 'package:flutter_test/flutter_test.dart';
import 'package:juma_ui_crm/features/purchases/domain/value_objects/purchase_number.dart';

void main() {
  test('throws for an empty value', () {
    expect(() => PurchaseNumber(''), throwsArgumentError);
  });

  test('throws for a whitespace-only value', () {
    expect(() => PurchaseNumber('   '), throwsArgumentError);
  });

  test('trims surrounding whitespace', () {
    expect(PurchaseNumber('  PO-0001  ').value, 'PO-0001');
  });

  test('equality and hashCode are based on the trimmed value', () {
    expect(PurchaseNumber('PO-0001'), PurchaseNumber('  PO-0001  '));
    expect(
      PurchaseNumber('PO-0001').hashCode,
      PurchaseNumber('  PO-0001  ').hashCode,
    );
  });

  test('toString returns the value', () {
    expect(PurchaseNumber('PO-0001').toString(), 'PO-0001');
  });
}
