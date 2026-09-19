import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:juma_ui_crm/features/partners/domain/entities/partner.dart';
import 'package:juma_ui_crm/features/partners/domain/value_objects/partner_category.dart';
import 'package:juma_ui_crm/features/purchases/domain/value_objects/purchase_date_range.dart';
import 'package:juma_ui_crm/features/purchases/presentation/providers/purchases_providers.dart';

void main() {
  test('purchaseOrdersSupplierFilterProvider defaults to null', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(container.read(purchaseOrdersSupplierFilterProvider), isNull);
  });

  test('purchaseOrdersSupplierFilterProvider is settable', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final partner = Partner(
      id: 's1',
      displayName: 'Жеткізуші А',
      category: PartnerCategory.ldsp,
      isActive: true,
      createdAt: DateTime(2026, 7, 1),
      hasExtendedAccess: true,
      hasFinancialAccess: true,
    );
    container.read(purchaseOrdersSupplierFilterProvider.notifier).state =
        partner;
    expect(container.read(purchaseOrdersSupplierFilterProvider), partner);
  });

  test('purchaseOrdersDateRangeProvider defaults to null', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(container.read(purchaseOrdersDateRangeProvider), isNull);
  });

  test('purchaseOrdersDateRangeProvider is settable', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final range = PurchaseDateRange(
      from: DateTime(2026, 7, 1),
      to: DateTime(2026, 7, 31),
    );
    container.read(purchaseOrdersDateRangeProvider.notifier).state = range;
    expect(container.read(purchaseOrdersDateRangeProvider), range);
  });
}
