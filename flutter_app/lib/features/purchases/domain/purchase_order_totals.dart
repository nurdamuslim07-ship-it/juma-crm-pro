/// Pure total-computation logic, mirroring exactly what the Postgres
/// triggers `sync_purchase_order_item_total()`/`sync_purchase_order_total()`
/// do server-side (supabase/migrations/20260713000022_purchases_module.sql)
/// — kept here, out of the form widget, so the PO draft form's live
/// preview total can't drift from what the server will actually store,
/// and so the arithmetic itself is directly unit-testable.
library;

/// Rounds to the nearest tiyn, same as Postgres's `round(numeric)`.
int computeItemTotalTiyn({required num quantity, required int unitPriceTiyn}) {
  return (quantity * unitPriceTiyn).round();
}

int computeSubtotalTiyn(List<int> itemTotalsTiyn) {
  return itemTotalsTiyn.fold(0, (sum, total) => sum + total);
}

int computeOrderTotalTiyn({
  required int subtotalTiyn,
  required int deliveryCostTiyn,
  required int vatTiyn,
  required int discountTiyn,
}) {
  return subtotalTiyn + deliveryCostTiyn + vatTiyn - discountTiyn;
}
