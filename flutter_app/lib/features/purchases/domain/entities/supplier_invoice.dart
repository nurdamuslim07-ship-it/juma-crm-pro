import 'package:flutter/foundation.dart';

import 'supplier_invoice_status.dart';

/// See `get_supplier_invoices()` — backs the "Invoices" tab on a
/// supplier's Partner detail screen and the Purchase Detail screen.
@immutable
class SupplierInvoice {
  const SupplierInvoice({
    required this.id,
    required this.invoiceNumber,
    this.purchaseOrderId,
    this.purchaseOrderNumber,
    required this.amountTiyn,
    required this.status,
    required this.issuedAt,
    this.dueDate,
    required this.paidAmountTiyn,
  });

  final String id;
  final String invoiceNumber;
  final String? purchaseOrderId;
  final String? purchaseOrderNumber;
  final int amountTiyn;
  final SupplierInvoiceStatus status;
  final DateTime issuedAt;
  final DateTime? dueDate;
  final int paidAmountTiyn;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SupplierInvoice &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
