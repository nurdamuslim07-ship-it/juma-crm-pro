/// Mirrors the `supplier_invoice_status` Postgres enum — maintained by
/// `recalc_supplier_invoice_status()` from the sum of
/// `active_supplier_payments` against the invoice, never set directly
/// by the client.
enum SupplierInvoiceStatus { unpaid, partial, paid }

extension SupplierInvoiceStatusX on SupplierInvoiceStatus {
  static SupplierInvoiceStatus fromKey(String key) {
    return SupplierInvoiceStatus.values.firstWhere(
      (s) => s.name == key,
      orElse: () => SupplierInvoiceStatus.unpaid,
    );
  }
}
