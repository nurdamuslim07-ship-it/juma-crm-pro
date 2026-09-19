import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:juma_ui_crm/core/widgets/app_button.dart';
import 'package:juma_ui_crm/features/purchases/presentation/widgets/add_purchase_order_item_sheet.dart';
import 'package:juma_ui_crm/features/warehouse/domain/entities/material_stock.dart';

/// Quantity/unit-price validation — [AddPurchaseOrderItemSheet] now
/// routes through the shared `validateItemQuantity`/
/// `validateItemUnitPriceTiyn` from `purchase_validation.dart` instead
/// of its own ad-hoc checks. No provider overrides needed: validation
/// runs entirely client-side before any repository call.
void main() {
  const material = MaterialStock(
    materialId: 'm1',
    name: 'ЛДСП 16мм',
    unit: 'парақ',
    minQuantity: 1,
    costPerUnitTiyn: 850000,
    totalQuantity: 100,
    totalReserved: 0,
    availableQuantity: 100,
    isLowStock: false,
  );

  Future<void> pumpSheet(WidgetTester tester) {
    return tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: AddPurchaseOrderItemSheet(material: material)),
        ),
      ),
    );
  }

  testWidgets('shows quantity and location errors when both are left empty', (
    tester,
  ) async {
    await pumpSheet(tester);

    await tester.tap(find.byType(AppButton));
    await tester.pump();

    expect(find.text('Мөлшер 0-ден үлкен болуы керек'), findsOneWidget);
    expect(find.text('Әр материалға қойма орнын көрсетіңіз'), findsOneWidget);
  });

  testWidgets('shows a unit-price error for a negative price', (tester) async {
    await pumpSheet(tester);

    await tester.enterText(find.byType(TextField).first, '5');
    final unitPriceField = find.byType(TextField).at(1);
    await tester.enterText(unitPriceField, '-100');
    await tester.tap(find.byType(AppButton));
    await tester.pump();

    expect(find.text('Бірлік бағасы теріс болмауы керек'), findsOneWidget);
  });
}
