import 'package:flutter_test/flutter_test.dart';
import 'package:juma_ui_crm/features/purchases/data/models/supplier_balance_model.dart';

void main() {
  test('fromRow parses a get_partners() row with an outstanding debt', () {
    final model = SupplierBalanceModel.fromRow({
      'id': 's1',
      'display_name': 'Жеткізуші А',
      'balance_tiyn': 500000,
      'has_financial_access': true,
    });
    expect(model.partnerId, 's1');
    expect(model.partnerName, 'Жеткізуші А');
    expect(model.balanceTiyn, 500000);
    expect(model.hasFinancialAccess, isTrue);
  });

  test('fromRow parses a null balance_tiyn (redacted or zero)', () {
    final model = SupplierBalanceModel.fromRow({
      'id': 's1',
      'display_name': 'Жеткізуші А',
      'balance_tiyn': null,
      'has_financial_access': false,
    });
    expect(model.balanceTiyn, isNull);
    expect(model.hasFinancialAccess, isFalse);
  });

  test('fromRow defaults a missing display_name to an empty string', () {
    final model = SupplierBalanceModel.fromRow({
      'id': 's1',
      'display_name': null,
      'balance_tiyn': 0,
      'has_financial_access': true,
    });
    expect(model.partnerName, '');
  });

  test('fromRow parses an integer balance_tiyn arriving as num', () {
    final model = SupplierBalanceModel.fromRow({
      'id': 's1',
      'display_name': 'Жеткізуші А',
      'balance_tiyn': -300000,
      'has_financial_access': true,
    });
    expect(model.balanceTiyn, -300000);
  });
}
