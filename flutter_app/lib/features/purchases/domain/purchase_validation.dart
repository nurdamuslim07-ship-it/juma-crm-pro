/// Pure validation functions mirroring exactly what
/// supabase/migrations/20260713000022_purchases_module.sql enforces
/// server-side — kept here (not inline in a widget) so the rules are
/// directly unit-testable, same convention as
/// purchase_order_totals.dart. These are advisory/UX-only: the RPCs'
/// own checks (`check (quantity > 0)`, the draft-only edit guard in
/// `update_purchase_order()`, the status-transition guards in
/// `approve_purchase_order()`/`reject_purchase_order()`/
/// `mark_purchase_order_delivered()`/`cancel_purchase_order()`/
/// `receive_purchase_order()`) remain the real enforcement boundary.
///
/// Every function returns `null` for "valid" and a Kazakh, user-facing
/// error message otherwise — the same shape every form screen in this
/// app already uses for field-level `errorText`, so callers don't need
/// a new error-handling convention.
library;

import 'entities/purchase_order_item.dart';
import 'entities/purchase_order_status.dart';

String? validateSupplierSelected(String? supplierPartnerId) {
  if (supplierPartnerId == null || supplierPartnerId.trim().isEmpty) {
    return 'Жеткізушіні таңдаңыз';
  }
  return null;
}

String? validateHasItems(int itemCount) {
  if (itemCount <= 0) {
    return 'Кемінде бір материал қосыңыз';
  }
  return null;
}

String? validateItemQuantity(num quantity) {
  if (quantity <= 0) {
    return 'Мөлшер 0-ден үлкен болуы керек';
  }
  return null;
}

String? validateItemUnitPriceTiyn(int unitPriceTiyn) {
  if (unitPriceTiyn < 0) {
    return 'Бірлік бағасы теріс болмауы керек';
  }
  return null;
}

/// Shared by delivery cost / VAT / discount — all three are
/// `check (... >= 0)` in `purchase_orders`.
String? validateNonNegativeAdjustmentTiyn(int amountTiyn, String fieldLabel) {
  if (amountTiyn < 0) {
    return '$fieldLabel теріс болмауы керек';
  }
  return null;
}

/// `receive_purchase_order()` currently receives a PO's items at
/// exactly their ordered quantities (no partial/adjusted receiving is
/// supported by that RPC yet — see its doc comment), so this isn't
/// wired into any usecase today. Provided ready-made for when partial
/// receiving is added.
String? validateReceivedQuantity({
  required num receivedQuantity,
  required num orderedQuantity,
}) {
  if (receivedQuantity > orderedQuantity) {
    return 'Қабылданған мөлшер тапсырыс мөлшерінен аспауы керек';
  }
  return null;
}

/// [invoiceRemainingTiyn] is the invoice's `amount_tiyn - paid_amount_tiyn`.
/// Pass `null` when the payment isn't tied to a specific invoice — a
/// reason-less advance ("Аванс") is explicitly allowed to have no
/// upper bound, matching `record_supplier_payment()`'s own "warn, don't
/// block" design (overpaying simply becomes a negative
/// `partners.balance_tiyn`, i.e. an advance).
String? validatePaymentAmount({
  required int amountTiyn,
  int? invoiceRemainingTiyn,
}) {
  if (amountTiyn <= 0) {
    return 'Төлем сомасы 0-ден үлкен болуы керек';
  }
  if (invoiceRemainingTiyn != null && amountTiyn > invoiceRemainingTiyn) {
    return 'Төлем сомасы шот-фактураның қалған сомасынан аспауы керек';
  }
  return null;
}

const _terminalStatuses = {
  PurchaseOrderStatus.received,
  PurchaseOrderStatus.rejected,
  PurchaseOrderStatus.cancelled,
};

bool isTerminalStatus(PurchaseOrderStatus status) =>
    _terminalStatuses.contains(status);

String? validateNotTerminal(PurchaseOrderStatus status) {
  if (isTerminalStatus(status)) {
    return 'Аяқталған тапсырысты өзгертуге болмайды';
  }
  return null;
}

/// Mirrors the exact transition graph enforced by
/// `approve_purchase_order()` (draft -> approved),
/// `reject_purchase_order()` (draft|approved -> rejected),
/// `mark_purchase_order_delivered()` (approved -> delivered),
/// `receive_purchase_order()` (delivered -> received), and
/// `cancel_purchase_order()` (draft|approved|delivered -> cancelled).
bool canTransitionPurchaseOrderStatus(
  PurchaseOrderStatus from,
  PurchaseOrderStatus to,
) {
  switch (to) {
    case PurchaseOrderStatus.approved:
      return from == PurchaseOrderStatus.draft;
    case PurchaseOrderStatus.rejected:
      return from == PurchaseOrderStatus.draft ||
          from == PurchaseOrderStatus.approved;
    case PurchaseOrderStatus.delivered:
      return from == PurchaseOrderStatus.approved;
    case PurchaseOrderStatus.received:
      return from == PurchaseOrderStatus.delivered;
    case PurchaseOrderStatus.cancelled:
      return from == PurchaseOrderStatus.draft ||
          from == PurchaseOrderStatus.approved ||
          from == PurchaseOrderStatus.delivered;
    case PurchaseOrderStatus.draft:
      return false;
  }
}

String? validateStatusTransition(
  PurchaseOrderStatus from,
  PurchaseOrderStatus to,
) {
  if (!canTransitionPurchaseOrderStatus(from, to)) {
    return 'Бұл статус ауысуына рұқсат жоқ';
  }
  return null;
}

/// Composite check shared by `create_purchase_order()`/
/// `update_purchase_order()`'s Flutter usecases — runs every header
/// and line-item rule in one call so both usecases validate
/// identically without duplicating the checks.
String? validatePurchaseOrderInput({
  required String? supplierPartnerId,
  required List<PurchaseOrderItem> items,
  required int deliveryCostTiyn,
  required int vatTiyn,
  required int discountTiyn,
}) {
  final supplierError = validateSupplierSelected(supplierPartnerId);
  if (supplierError != null) return supplierError;

  final itemsError = validateHasItems(items.length);
  if (itemsError != null) return itemsError;

  for (final item in items) {
    final quantityError = validateItemQuantity(item.quantity);
    if (quantityError != null) return quantityError;
    final priceError = validateItemUnitPriceTiyn(item.unitPriceTiyn);
    if (priceError != null) return priceError;
  }

  final deliveryError = validateNonNegativeAdjustmentTiyn(
    deliveryCostTiyn,
    'Жеткізу құны',
  );
  if (deliveryError != null) return deliveryError;

  final vatError = validateNonNegativeAdjustmentTiyn(vatTiyn, 'ҚҚС');
  if (vatError != null) return vatError;

  final discountError = validateNonNegativeAdjustmentTiyn(
    discountTiyn,
    'Жеңілдік',
  );
  if (discountError != null) return discountError;

  return null;
}
