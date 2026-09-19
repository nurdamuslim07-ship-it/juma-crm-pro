import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:juma_ui_crm/features/auth/presentation/providers/auth_providers.dart';
import 'package:juma_ui_crm/features/purchases/domain/entities/purchase_order_status.dart';
import 'package:juma_ui_crm/features/purchases/domain/entities/purchase_order_summary.dart';
import 'package:juma_ui_crm/features/purchases/presentation/providers/purchases_providers.dart';
import 'package:juma_ui_crm/features/purchases/presentation/screens/purchase_orders_screen.dart';
import 'package:juma_ui_crm/features/purchases/presentation/widgets/purchase_order_list_tile.dart';
import 'package:juma_ui_crm/features/purchases/presentation/widgets/purchase_orders_table.dart';

/// Responsive layout — phone gets a card list ([PurchaseOrderListTile]),
/// tablet/desktop/web gets a data table ([PurchaseOrdersTable]); same
/// data, chrome-only branching (see purchase_orders_screen.dart's doc
/// comment / RESPONSIVE_LAYOUT.md).
final _orders = [
  PurchaseOrderSummary(
    id: 'po1',
    orderNumber: 'PO-0001',
    supplierPartnerId: 's1',
    supplierName: 'Жеткізуші А',
    status: PurchaseOrderStatus.draft,
    itemsCount: 1,
    totalAmountTiyn: 100000,
    createdAt: DateTime(2026, 7, 1),
  ),
];

Future<void> _pump(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  return tester.pumpWidget(
    ProviderScope(
      overrides: [
        purchaseOrdersListProvider.overrideWith((ref) => Future.value(_orders)),
        currentUserProvider.overrideWithValue(null),
      ],
      child: const MaterialApp(home: PurchaseOrdersScreen()),
    ),
  );
}

void main() {
  testWidgets('phone width renders a card list, not a table', (tester) async {
    await _pump(tester, const Size(400, 900));
    await tester.pumpAndSettle();

    expect(find.byType(PurchaseOrderListTile), findsOneWidget);
    expect(find.byType(PurchaseOrdersTable), findsNothing);
  });

  testWidgets('desktop width renders a table, not a card list', (tester) async {
    await _pump(tester, const Size(1200, 900));
    await tester.pumpAndSettle();

    expect(find.byType(PurchaseOrdersTable), findsOneWidget);
    expect(find.byType(PurchaseOrderListTile), findsNothing);
  });
}
