import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/purchase_analytics.dart';
import '../entities/purchase_order_detail.dart';
import '../entities/purchase_order_item.dart';
import '../entities/purchase_order_status.dart';
import '../entities/purchase_order_summary.dart';
import '../entities/supplier_balance.dart';
import '../entities/supplier_invoice.dart';
import '../entities/supplier_payment.dart';

abstract class PurchasesRepository {
  /// Routed through `get_purchase_orders()` — empty for a caller with
  /// no `purchases.read`.
  Future<Either<Failure, List<PurchaseOrderSummary>>> getPurchaseOrders({
    PurchaseOrderStatus? status,
    String? supplierPartnerId,
    String? search,
  });

  /// Routed through `get_purchase_order_detail()` — raises (surfaced
  /// as a Failure) for a caller with no `purchases.read` at all.
  Future<Either<Failure, PurchaseOrderDetail>> getPurchaseOrderDetail(
    String id,
  );

  /// Requirement: "Purchase Order құру" — director/manager/purchaser.
  Future<Either<Failure, String>> createPurchaseOrder({
    required String orderNumber,
    required String supplierPartnerId,
    required List<PurchaseOrderItem> items,
    String? responsibleEmployeeId,
    DateTime? expectedDeliveryDate,
    int deliveryCostTiyn = 0,
    int vatTiyn = 0,
    int discountTiyn = 0,
    String? comment,
  });

  /// Requirement: "Өңдеу" — draft-only, enforced server-side.
  Future<Either<Failure, Unit>> updatePurchaseOrder({
    required String id,
    required String supplierPartnerId,
    required List<PurchaseOrderItem> items,
    String? responsibleEmployeeId,
    DateTime? expectedDeliveryDate,
    int deliveryCostTiyn = 0,
    int vatTiyn = 0,
    int discountTiyn = 0,
    String? comment,
  });

  /// Requirement: "Бекіту" — director/purchaser.
  Future<Either<Failure, Unit>> approvePurchaseOrder(String id);

  /// Requirement: "Бас тарту" — director/purchaser.
  Future<Either<Failure, Unit>> rejectPurchaseOrder(
    String id, {
    String? reason,
  });

  /// Requirement: "Жеткізілді" — director/purchaser.
  Future<Either<Failure, Unit>> markPurchaseOrderDelivered(String id);

  /// Cancels a draft (purchases.write) or an approved/delivered order
  /// (purchases.approve) — never a received one.
  Future<Either<Failure, Unit>> cancelPurchaseOrder(
    String id, {
    String? reason,
  });

  /// Requirement: "Қабылдау" + full Warehouse/Production integration —
  /// routed through `receive_purchase_order()`, which itself calls the
  /// Warehouse module's `receive_materials()` per line item. Returns
  /// the auto-created supplier invoice's id.
  Future<Either<Failure, String>> receivePurchaseOrder(String id);

  /// Requirement: Production integration — "Production күтіп тұрған
  /// материалдарды көрсету". Keyed by material id.
  Future<Either<Failure, Map<String, num>>> getPendingPurchaseQuantities();

  /// Requirement: Partners integration — "Invoices көру".
  Future<Either<Failure, List<SupplierInvoice>>> getSupplierInvoices(
    String partnerId,
  );

  /// Requirement: Partners integration — "Payments көру".
  Future<Either<Failure, List<SupplierPayment>>> getSupplierPayments(
    String partnerId,
  );

  /// Requirement: "Жеткізушіге төлем" — accountant/director. The
  /// idempotency key is generated internally by the datasource (same
  /// convention as PaymentRemoteDataSource), never managed by the UI.
  Future<Either<Failure, Unit>> recordSupplierPayment({
    required String partnerId,
    required int amountTiyn,
    required String methodId,
    String? supplierInvoiceId,
    String? cashboxId,
    String? bankAccountId,
    DateTime? paidAt,
    String? comment,
  });

  Future<Either<Failure, Unit>> reverseSupplierPayment(
    String paymentId,
    String reason,
  );

  /// Requirement: "Purchase Analytics".
  Future<Either<Failure, PurchaseAnalytics>> getPurchaseAnalytics();

  /// method key ('cash'/'kaspi'/'bank_transfer'/'card'/'other') -> its
  /// `payment_methods.id` — same small lookup the Payments module's
  /// own datasource caches, reused here rather than duplicated as a
  /// cross-feature dependency.
  Future<Either<Failure, Map<String, String>>> getPaymentMethodIds();

  /// Requirement: "SupplierBalance" — routed through the Partners
  /// module's own `get_partners(p_id: ...)` RPC (no new Purchases RPC;
  /// `partners.balance_tiyn` is already the authoritative ledger
  /// `receive_purchase_order()`/`record_supplier_payment()`/
  /// `reverse_supplier_payment()` maintain).
  Future<Either<Failure, SupplierBalance>> getSupplierBalance(String partnerId);
}
