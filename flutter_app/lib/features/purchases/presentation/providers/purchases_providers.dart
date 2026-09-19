import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/supabase_provider.dart';
import '../../../auth/domain/entities/auth_user.dart';
import '../../../partners/domain/entities/partner.dart';
import '../../data/datasources/purchases_remote_datasource.dart';
import '../../data/repositories/purchases_repository_impl.dart';
import '../../domain/entities/purchase_analytics.dart';
import '../../domain/entities/purchase_order_detail.dart';
import '../../domain/entities/purchase_order_status.dart';
import '../../domain/entities/purchase_order_summary.dart';
import '../../domain/entities/supplier_balance.dart';
import '../../domain/entities/supplier_invoice.dart';
import '../../domain/entities/supplier_payment.dart';
import '../../domain/repositories/purchases_repository.dart';
import '../../domain/usecases/add_supplier_payment_usecase.dart';
import '../../domain/usecases/approve_purchase_order_usecase.dart';
import '../../domain/usecases/cancel_purchase_order_usecase.dart';
import '../../domain/usecases/create_purchase_order_usecase.dart';
import '../../domain/usecases/get_payment_method_ids_usecase.dart';
import '../../domain/usecases/get_pending_production_material_needs_usecase.dart';
import '../../domain/usecases/get_pending_purchase_quantities_usecase.dart';
import '../../domain/usecases/get_purchase_analytics_usecase.dart';
import '../../domain/usecases/get_purchase_order_detail_usecase.dart';
import '../../domain/usecases/get_purchase_orders_usecase.dart';
import '../../domain/usecases/get_supplier_balance_usecase.dart';
import '../../domain/usecases/get_supplier_invoices_usecase.dart';
import '../../domain/usecases/get_supplier_payments_usecase.dart';
import '../../domain/usecases/mark_purchase_delivered_usecase.dart';
import '../../domain/usecases/mark_purchase_order_delivered_usecase.dart';
import '../../domain/usecases/receive_purchase_order_usecase.dart';
import '../../domain/usecases/record_supplier_payment_usecase.dart';
import '../../domain/usecases/reject_purchase_order_usecase.dart';
import '../../domain/usecases/reverse_supplier_payment_usecase.dart';
import '../../domain/usecases/update_purchase_order_usecase.dart';
import '../../domain/value_objects/purchase_date_range.dart';

final purchasesRemoteDataSourceProvider = Provider<PurchasesRemoteDataSource>(
  (ref) => PurchasesRemoteDataSource(ref.watch(supabaseClientProvider)),
);

final purchasesRepositoryProvider = Provider<PurchasesRepository>(
  (ref) =>
      PurchasesRepositoryImpl(ref.watch(purchasesRemoteDataSourceProvider)),
);

final getPurchaseOrdersUseCaseProvider = Provider<GetPurchaseOrdersUseCase>(
  (ref) => GetPurchaseOrdersUseCase(ref.watch(purchasesRepositoryProvider)),
);

final getPurchaseOrderDetailUseCaseProvider =
    Provider<GetPurchaseOrderDetailUseCase>(
      (ref) =>
          GetPurchaseOrderDetailUseCase(ref.watch(purchasesRepositoryProvider)),
    );

final createPurchaseOrderUseCaseProvider = Provider<CreatePurchaseOrderUseCase>(
  (ref) => CreatePurchaseOrderUseCase(ref.watch(purchasesRepositoryProvider)),
);

final updatePurchaseOrderUseCaseProvider = Provider<UpdatePurchaseOrderUseCase>(
  (ref) => UpdatePurchaseOrderUseCase(ref.watch(purchasesRepositoryProvider)),
);

final approvePurchaseOrderUseCaseProvider =
    Provider<ApprovePurchaseOrderUseCase>(
      (ref) =>
          ApprovePurchaseOrderUseCase(ref.watch(purchasesRepositoryProvider)),
    );

final rejectPurchaseOrderUseCaseProvider = Provider<RejectPurchaseOrderUseCase>(
  (ref) => RejectPurchaseOrderUseCase(ref.watch(purchasesRepositoryProvider)),
);

final markPurchaseOrderDeliveredUseCaseProvider =
    Provider<MarkPurchaseOrderDeliveredUseCase>(
      (ref) => MarkPurchaseOrderDeliveredUseCase(
        ref.watch(purchasesRepositoryProvider),
      ),
    );

final cancelPurchaseOrderUseCaseProvider = Provider<CancelPurchaseOrderUseCase>(
  (ref) => CancelPurchaseOrderUseCase(ref.watch(purchasesRepositoryProvider)),
);

final receivePurchaseOrderUseCaseProvider =
    Provider<ReceivePurchaseOrderUseCase>(
      (ref) =>
          ReceivePurchaseOrderUseCase(ref.watch(purchasesRepositoryProvider)),
    );

final getPendingPurchaseQuantitiesUseCaseProvider =
    Provider<GetPendingPurchaseQuantitiesUseCase>(
      (ref) => GetPendingPurchaseQuantitiesUseCase(
        ref.watch(purchasesRepositoryProvider),
      ),
    );

final getSupplierInvoicesUseCaseProvider = Provider<GetSupplierInvoicesUseCase>(
  (ref) => GetSupplierInvoicesUseCase(ref.watch(purchasesRepositoryProvider)),
);

final getSupplierPaymentsUseCaseProvider = Provider<GetSupplierPaymentsUseCase>(
  (ref) => GetSupplierPaymentsUseCase(ref.watch(purchasesRepositoryProvider)),
);

final recordSupplierPaymentUseCaseProvider =
    Provider<RecordSupplierPaymentUseCase>(
      (ref) =>
          RecordSupplierPaymentUseCase(ref.watch(purchasesRepositoryProvider)),
    );

final reverseSupplierPaymentUseCaseProvider =
    Provider<ReverseSupplierPaymentUseCase>(
      (ref) =>
          ReverseSupplierPaymentUseCase(ref.watch(purchasesRepositoryProvider)),
    );

final getPurchaseAnalyticsUseCaseProvider =
    Provider<GetPurchaseAnalyticsUseCase>(
      (ref) =>
          GetPurchaseAnalyticsUseCase(ref.watch(purchasesRepositoryProvider)),
    );

final getPaymentMethodIdsUseCaseProvider = Provider<GetPaymentMethodIdsUseCase>(
  (ref) => GetPaymentMethodIdsUseCase(ref.watch(purchasesRepositoryProvider)),
);

final getSupplierBalanceUseCaseProvider = Provider<GetSupplierBalanceUseCase>(
  (ref) => GetSupplierBalanceUseCase(ref.watch(purchasesRepositoryProvider)),
);

/// Additive aliases requested alongside the above — each delegates to
/// the already-committed usecase of the same behaviour rather than
/// renaming it, per the owner's "Тек қосу" (additive only) decision.
final getPendingProductionMaterialNeedsUseCaseProvider =
    Provider<GetPendingProductionMaterialNeedsUseCase>(
      (ref) => GetPendingProductionMaterialNeedsUseCase(
        ref.watch(getPendingPurchaseQuantitiesUseCaseProvider),
      ),
    );

final markPurchaseDeliveredUseCaseProvider =
    Provider<MarkPurchaseDeliveredUseCase>(
      (ref) => MarkPurchaseDeliveredUseCase(
        ref.watch(markPurchaseOrderDeliveredUseCaseProvider),
      ),
    );

final addSupplierPaymentUseCaseProvider = Provider<AddSupplierPaymentUseCase>(
  (ref) => AddSupplierPaymentUseCase(
    ref.watch(recordSupplierPaymentUseCaseProvider),
  ),
);

final purchaseOrdersSearchQueryProvider = StateProvider<String>((ref) => '');
final purchaseOrdersStatusFilterProvider = StateProvider<PurchaseOrderStatus?>(
  (ref) => null,
);

/// Requirement: "Жеткізуші бойынша фильтр" — stores the picked [Partner]
/// itself (not just its id) so the list screen's filter chip can show
/// the supplier's name without a second lookup.
final purchaseOrdersSupplierFilterProvider = StateProvider<Partner?>(
  (ref) => null,
);

/// Requirement: "Күн диапазоны" — applied client-side over the already
/// server-filtered list (see [purchaseOrdersListProvider]'s doc
/// comment for why: `get_purchase_orders()` has no date-range
/// parameter, and this stage may not touch the RPC).
final purchaseOrdersDateRangeProvider = StateProvider<PurchaseDateRange?>(
  (ref) => null,
);

/// [purchaseOrdersDateRangeProvider] is intentionally NOT applied here
/// — `get_purchase_orders()` (see
/// supabase/migrations/20260713000022_purchases_module.sql) has no
/// date-range parameter, and this stage may not touch RPCs. The list
/// screen applies that filter itself, client-side, over this
/// provider's already-fetched (search/status/supplier) result.
final purchaseOrdersListProvider =
    FutureProvider.autoDispose<List<PurchaseOrderSummary>>((ref) {
      final search = ref.watch(purchaseOrdersSearchQueryProvider);
      final status = ref.watch(purchaseOrdersStatusFilterProvider);
      final supplier = ref.watch(purchaseOrdersSupplierFilterProvider);
      return ref
          .watch(getPurchaseOrdersUseCaseProvider)
          .call(status: status, search: search, supplierPartnerId: supplier?.id)
          .then((either) => either.match((failure) => throw failure, (d) => d));
    });

/// Backs the "Purchase History" tab on a supplier's Partner detail
/// screen — a separate provider from [purchaseOrdersListProvider] so
/// opening a partner card never mutates the main Purchase Orders
/// screen's shared search/status filter state.
final purchaseOrdersBySupplierProvider = FutureProvider.autoDispose
    .family<List<PurchaseOrderSummary>, String>((ref, supplierPartnerId) {
      return ref
          .watch(getPurchaseOrdersUseCaseProvider)
          .call(supplierPartnerId: supplierPartnerId)
          .then((either) => either.match((failure) => throw failure, (d) => d));
    });

final purchaseOrderDetailProvider = FutureProvider.autoDispose
    .family<PurchaseOrderDetail, String>((ref, id) {
      return ref
          .watch(getPurchaseOrderDetailUseCaseProvider)
          .call(id)
          .then((either) => either.match((failure) => throw failure, (d) => d));
    });

/// Requirement: Production integration — "Production күтіп тұрған
/// материалдарды көрсету". Keyed by material id; the Production
/// module's `MaterialAvailabilitySection` widget watches this to show
/// an optional "жолда" (in transit) badge.
final pendingPurchaseQuantitiesProvider =
    FutureProvider.autoDispose<Map<String, num>>((ref) {
      return ref
          .watch(getPendingPurchaseQuantitiesUseCaseProvider)
          .call()
          .then((either) => either.match((failure) => throw failure, (d) => d));
    });

final supplierInvoicesProvider = FutureProvider.autoDispose
    .family<List<SupplierInvoice>, String>((ref, partnerId) {
      return ref
          .watch(getSupplierInvoicesUseCaseProvider)
          .call(partnerId)
          .then((either) => either.match((failure) => throw failure, (d) => d));
    });

final supplierPaymentsProvider = FutureProvider.autoDispose
    .family<List<SupplierPayment>, String>((ref, partnerId) {
      return ref
          .watch(getSupplierPaymentsUseCaseProvider)
          .call(partnerId)
          .then((either) => either.match((failure) => throw failure, (d) => d));
    });

/// Requirement: "SupplierBalance" — the supplier side of a Partner's
/// `balance_tiyn`, read through the Partners module's own
/// `get_partners(p_id: ...)` RPC (no new Purchases RPC).
final supplierBalanceProvider = FutureProvider.autoDispose
    .family<SupplierBalance, String>((ref, partnerId) {
      return ref
          .watch(getSupplierBalanceUseCaseProvider)
          .call(partnerId)
          .then((either) => either.match((failure) => throw failure, (d) => d));
    });

final purchaseAnalyticsProvider = FutureProvider.autoDispose<PurchaseAnalytics>(
  (ref) {
    return ref
        .watch(getPurchaseAnalyticsUseCaseProvider)
        .call()
        .then((either) => either.match((failure) => throw failure, (d) => d));
  },
);

/// Rarely changes — a plain (non-autoDispose) cached fetch, same
/// convention as `productionStagesProvider`/`materialCategoriesProvider`.
final paymentMethodIdsProvider = FutureProvider<Map<String, String>>((ref) {
  return ref
      .watch(getPaymentMethodIdsUseCaseProvider)
      .call()
      .then((either) => either.match((failure) => throw failure, (d) => d));
});

/// UI-convenience only, per SECURITY_PLAN.md finding #6 — the RPCs'
/// own permission checks (see
/// supabase/migrations/20260713000022_purchases_module.sql) are the
/// real authorization boundary.
extension PurchasesAccess on AuthUser {
  bool get canReadPurchases =>
      isDirector ||
      hasRole('manager') ||
      hasRole('purchaser') ||
      hasRole('accountant') ||
      hasRole('warehouse') ||
      hasRole('workshop_manager');
  bool get canWritePurchases =>
      isDirector || hasRole('manager') || hasRole('purchaser');
  bool get canApprovePurchases => isDirector || hasRole('purchaser');
  bool get canReceivePurchases =>
      isDirector || hasRole('purchaser') || hasRole('warehouse');
  bool get canPayPurchases => isDirector || hasRole('accountant');
}
