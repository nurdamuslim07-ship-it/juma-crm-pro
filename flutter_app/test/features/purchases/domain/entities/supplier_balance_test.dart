import 'package:flutter_test/flutter_test.dart';
import 'package:juma_ui_crm/features/purchases/domain/entities/supplier_balance.dart';

void main() {
  test('equality and hashCode are based on partnerId only', () {
    const a = SupplierBalance(
      partnerId: 's1',
      partnerName: 'Жеткізуші А',
      balanceTiyn: 1000,
      hasFinancialAccess: true,
    );
    const b = SupplierBalance(
      partnerId: 's1',
      partnerName: 'Жеткізуші Б',
      balanceTiyn: -9999,
      hasFinancialAccess: false,
    );
    expect(a, equals(b));
    expect(a.hashCode, b.hashCode);
  });

  test('a positive balance is a debt, not an advance', () {
    const balance = SupplierBalance(
      partnerId: 's1',
      partnerName: 'Жеткізуші А',
      balanceTiyn: 5000,
      hasFinancialAccess: true,
    );
    expect(balance.isDebt, isTrue);
    expect(balance.isAdvance, isFalse);
    expect(balance.outstandingDebtTiyn, 5000);
    expect(balance.advanceTiyn, 0);
  });

  test('a negative balance is an advance, not a debt', () {
    const balance = SupplierBalance(
      partnerId: 's1',
      partnerName: 'Жеткізуші А',
      balanceTiyn: -5000,
      hasFinancialAccess: true,
    );
    expect(balance.isDebt, isFalse);
    expect(balance.isAdvance, isTrue);
    expect(balance.outstandingDebtTiyn, 0);
    expect(balance.advanceTiyn, 5000);
  });

  test('a null balance (redacted or zero) is neither debt nor advance', () {
    const balance = SupplierBalance(
      partnerId: 's1',
      partnerName: 'Жеткізуші А',
      hasFinancialAccess: false,
    );
    expect(balance.isDebt, isFalse);
    expect(balance.isAdvance, isFalse);
    expect(balance.outstandingDebtTiyn, 0);
    expect(balance.advanceTiyn, 0);
  });
}
