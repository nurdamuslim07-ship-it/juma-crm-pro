import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:juma_ui_crm/core/i18n/kk.dart';
import 'package:juma_ui_crm/features/auth/domain/entities/auth_user.dart';
import 'package:juma_ui_crm/features/auth/presentation/providers/auth_providers.dart';
import 'package:juma_ui_crm/features/purchases/domain/entities/purchase_order_detail.dart';
import 'package:juma_ui_crm/features/purchases/domain/entities/purchase_order_status.dart';
import 'package:juma_ui_crm/features/purchases/domain/entities/supplier_balance.dart';
import 'package:juma_ui_crm/features/purchases/domain/entities/supplier_invoice.dart';
import 'package:juma_ui_crm/features/purchases/presentation/providers/purchases_providers.dart';
import 'package:juma_ui_crm/features/purchases/presentation/screens/purchase_order_detail_screen.dart';

/// Status-based action visibility — [PurchaseOrderDetailScreen] gates
/// each action button on `detail.status` + the current user's role
/// (see PurchasesAccess in purchases_providers.dart). Every provider
/// the screen/its `_SupplierFinancialsSection` reads is overridden with
/// fixed values so this never touches Supabase/network.
const _strings = KkStrings();

const _directorUser = AuthUser(
  id: 'u1',
  fullName: 'Director',
  isActive: true,
  roleKeys: ['director'],
);

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
  // Tall viewport so every action button mounts within the sliver's
  // cache extent — this screen's ListView now has enough content
  // (supplier balance/invoice sections) to scroll past the default
  // 600pt test surface height, and find.text() only sees mounted
  // elements, not merely-scrollable ones.
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  return tester.pumpWidget(
    ProviderScope(
      overrides: [
        purchaseOrderDetailProvider.overrideWith(
          (ref, id) => Future.value(_detail(status)),
        ),
        currentUserProvider.overrideWithValue(_directorUser),
        supplierBalanceProvider.overrideWith(
          (ref, id) => Future.value(
            const SupplierBalance(
              partnerId: 's1',
              partnerName: 'Жеткізуші А',
              hasFinancialAccess: false,
            ),
          ),
        ),
        supplierInvoicesProvider.overrideWith(
          (ref, id) => Future.value(const <SupplierInvoice>[]),
        ),
      ],
      child: const MaterialApp(home: PurchaseOrderDetailScreen(orderId: 'po1')),
    ),
  );
}

void main() {
  setUpAll(() async {
    // AppFormatters.date() (used by the new createdAt row) needs the
    // 'kk' intl locale data loaded — never called elsewhere in this
    // test env since no prior widget test rendered a screen using it.
    await initializeDateFormatting('kk');
  });

  testWidgets('draft status shows Edit/Approve/Reject actions for a director', (
    tester,
  ) async {
    await _pump(tester, PurchaseOrderStatus.draft);
    await tester.pumpAndSettle();

    expect(find.text(_strings.purchasesEditAction), findsOneWidget);
    expect(find.text(_strings.purchasesApproveAction), findsOneWidget);
    expect(find.text(_strings.purchasesRejectAction), findsOneWidget);
    expect(find.text(_strings.purchasesDeliverAction), findsNothing);
    expect(find.text(_strings.purchasesReceiveAction), findsNothing);
  });

  testWidgets('approved status shows Deliver action, not Edit/Approve/Reject', (
    tester,
  ) async {
    await _pump(tester, PurchaseOrderStatus.approved);
    await tester.pumpAndSettle();

    expect(find.text(_strings.purchasesDeliverAction), findsOneWidget);
    expect(find.text(_strings.purchasesEditAction), findsNothing);
    expect(find.text(_strings.purchasesApproveAction), findsNothing);
  });

  testWidgets('delivered status shows Receive action', (tester) async {
    await _pump(tester, PurchaseOrderStatus.delivered);
    await tester.pumpAndSettle();

    expect(find.text(_strings.purchasesReceiveAction), findsOneWidget);
    expect(find.text(_strings.purchasesDeliverAction), findsNothing);
  });

  testWidgets('received (terminal) status shows no workflow actions', (
    tester,
  ) async {
    await _pump(tester, PurchaseOrderStatus.received);
    await tester.pumpAndSettle();

    expect(find.text(_strings.purchasesEditAction), findsNothing);
    expect(find.text(_strings.purchasesApproveAction), findsNothing);
    expect(find.text(_strings.purchasesDeliverAction), findsNothing);
    expect(find.text(_strings.purchasesReceiveAction), findsNothing);
    expect(find.text(_strings.purchasesCancelAction), findsNothing);
  });
}
