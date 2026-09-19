import 'package:flutter/foundation.dart';

import '../../../payments/domain/value_objects/payment_method.dart';

/// See `get_supplier_payments()`/`record_supplier_payment()`/
/// `reverse_supplier_payment()`. Reuses the Payments module's
/// [PaymentMethod] value object directly — same `payment_methods`
/// table, same 5 keys, no reason to model it twice.
@immutable
class SupplierPayment {
  const SupplierPayment({
    required this.id,
    this.supplierInvoiceId,
    this.invoiceNumber,
    required this.amountTiyn,
    this.method,
    required this.paidAt,
    required this.isReversed,
    this.reversalOf,
    this.comment,
    required this.createdAt,
  });

  final String id;
  final String? supplierInvoiceId;
  final String? invoiceNumber;
  final int amountTiyn;
  final PaymentMethod? method;
  final DateTime paidAt;

  /// True for status = 'reversed' (this row IS a reversal, or was
  /// itself reversed by a later row — the RPC only ever returns
  /// 'confirmed'/'reversed', never 'pending', since
  /// record_supplier_payment() inserts confirmed immediately).
  final bool isReversed;
  final String? reversalOf;
  final String? comment;
  final DateTime createdAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SupplierPayment &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
