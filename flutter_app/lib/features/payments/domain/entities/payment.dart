import 'package:flutter/foundation.dart';

import '../value_objects/payment_method.dart';

/// See DATABASE_SCHEMA.md "Payments & finance" and the Payments module
/// requirements. Every payment is its own row (never a mutable running
/// total on the order) — [amountTiyn] here is final and immutable
/// server-side (see `prevent_payment_tamper` trigger in
/// supabase/migrations/20260713000016_payments_module.sql); editing a
/// payment (requirement #13) may only ever change [method], [paidAt],
/// [comment], and [receiptUrl].
@immutable
class Payment {
  const Payment({
    required this.id,
    required this.orderId,
    required this.orderNumber,
    required this.clientId,
    required this.clientName,
    required this.amountTiyn,
    required this.method,
    required this.paidAt,
    this.recordedByEmployeeId,
    this.recordedByEmployeeName,
    this.comment,
    this.receiptUrl,
    required this.createdAt,
  });

  final String id;
  final String orderId;
  final String orderNumber;
  final String clientId;
  final String clientName;
  final int amountTiyn;
  final PaymentMethod method;
  final DateTime paidAt;
  final String? recordedByEmployeeId;
  final String? recordedByEmployeeName;
  final String? comment;
  final String? receiptUrl;
  final DateTime createdAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Payment && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
