/// Mirrors the `purchase_order_status` Postgres enum — see
/// supabase/migrations/20260713000022_purchases_module.sql for the
/// full workflow: draft -> approved -> delivered -> received, with
/// rejected/cancelled as terminal exits before received.
enum PurchaseOrderStatus {
  draft,
  approved,
  rejected,
  delivered,
  received,
  cancelled,
}

extension PurchaseOrderStatusX on PurchaseOrderStatus {
  static PurchaseOrderStatus fromKey(String key) {
    return PurchaseOrderStatus.values.firstWhere(
      (s) => s.name == key,
      orElse: () => PurchaseOrderStatus.draft,
    );
  }

  String get key => name;
}
