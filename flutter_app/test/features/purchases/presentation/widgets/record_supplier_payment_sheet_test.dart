import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:juma_ui_crm/core/widgets/app_button.dart';
import 'package:juma_ui_crm/features/purchases/presentation/widgets/record_supplier_payment_sheet.dart';

/// Overpayment prevention — [RecordSupplierPaymentSheet] must reject an
/// amount above [RecordSupplierPaymentSheet.invoiceRemainingTiyn]
/// before ever reaching a repository/network call (see
/// `purchase_validation.dart`'s `validatePaymentAmount`), so this needs
/// no provider overrides at all.
void main() {
  Future<void> pumpSheet(WidgetTester tester, {int? invoiceRemainingTiyn}) {
    return tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: RecordSupplierPaymentSheet(
              partnerId: 'p1',
              supplierInvoiceId: invoiceRemainingTiyn == null ? null : 'inv1',
              invoiceRemainingTiyn: invoiceRemainingTiyn,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets(
    'shows a Kazakh error when the amount exceeds the invoice remaining',
    (tester) async {
      await pumpSheet(tester, invoiceRemainingTiyn: 1000);

      await tester.enterText(find.byType(TextField).first, '1500');
      await tester.tap(find.byType(AppButton));
      await tester.pump();

      expect(
        find.text('Төлем сомасы шот-фактураның қалған сомасынан аспауы керек'),
        findsOneWidget,
      );
    },
  );

  testWidgets('shows a Kazakh error for a zero amount', (tester) async {
    await pumpSheet(tester);

    await tester.enterText(find.byType(TextField).first, '0');
    await tester.tap(find.byType(AppButton));
    await tester.pump();

    expect(find.text('Төлем сомасы 0-ден үлкен болуы керек'), findsOneWidget);
  });

  // "No upper bound for a reason-less advance" (amountTiyn with no
  // invoiceRemainingTiyn cap) is already covered at the pure domain
  // level by purchase_validation_test.dart's validatePaymentAmount()
  // cases — not repeated here, since asserting it at this widget layer
  // would require tapping Submit past validation into the real
  // repository/network call, which this test environment can't serve.
}
