import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:juma_ui_crm/core/i18n/kk.dart';
import 'package:juma_ui_crm/features/purchases/domain/entities/purchase_order_detail.dart';
import 'package:juma_ui_crm/features/purchases/domain/entities/purchase_order_status.dart';
import 'package:juma_ui_crm/features/purchases/presentation/providers/purchases_providers.dart';
import 'package:juma_ui_crm/features/purchases/presentation/screens/receive_materials_screen.dart';

/// [ReceiveMaterialsScreen]'s new defensive status guard — only a
/// `delivered` order may be receive-confirmed, even if this route is
/// reached directly (deep link/back-nav) rather than via the detail
/// screen's already-gated Receive button.
const _strings = KkStrings();

PurchaseOrderDetail _detail(PurchaseOrderStatus status) => PurchaseOrderDetail(
  id: 'po1',
  orderNumber: 'PO-0001',
  supplierPartnerId: 's1',
  supplierName: 'Жеткізуші А',
  status: status,
  deliveryCostTiyn: 0,
  vatTiyn: 0,
  discountTiyn: 0,
  subtotalTiyn: 100000,
  totalAmountTiyn: 100000,
  createdAt: DateTime(2026, 7, 1),
  items: const [],
);

Future<void> _pump(WidgetTester tester, PurchaseOrderStatus status) {
  return tester.pumpWidget(
    ProviderScope(
      overrides: [
        purchaseOrderDetailProvider.overrideWith(
          (ref, id) => Future.value(_detail(status)),
        ),
      ],
      child: const MaterialApp(home: ReceiveMaterialsScreen(orderId: 'po1')),
    ),
  );
}

void main() {
  testWidgets(
    'shows the guard message (not the confirm button) for a non-delivered order',
    (tester) async {
      await _pump(tester, PurchaseOrderStatus.draft);
      await tester.pumpAndSettle();

      expect(find.text(_strings.purchasesReceiveGuardMessage), findsOneWidget);
      expect(find.text(_strings.commonBack), findsOneWidget);
      expect(find.text(_strings.purchasesReceiveAction), findsNothing);
    },
  );

  testWidgets(
    'shows the confirm button (not the guard message) for a delivered order',
    (tester) async {
      await _pump(tester, PurchaseOrderStatus.delivered);
      await tester.pumpAndSettle();

      expect(find.text(_strings.purchasesReceiveAction), findsOneWidget);
      expect(find.text(_strings.purchasesReceiveGuardMessage), findsNothing);
    },
  );
}
