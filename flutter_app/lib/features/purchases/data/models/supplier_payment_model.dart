import '../../../payments/domain/value_objects/payment_method.dart';
import '../../domain/entities/supplier_payment.dart';

class SupplierPaymentModel extends SupplierPayment {
  const SupplierPaymentModel({
    required super.id,
    super.supplierInvoiceId,
    super.invoiceNumber,
    required super.amountTiyn,
    super.method,
    required super.paidAt,
    required super.isReversed,
    super.reversalOf,
    super.comment,
    required super.createdAt,
  });

  factory SupplierPaymentModel.fromRow(Map<String, dynamic> row) {
    final methodKey = row['method_key'] as String?;
    PaymentMethod? method;
    if (methodKey != null) {
      try {
        method = PaymentMethod.fromDbKey(methodKey);
      } on ArgumentError {
        method = null;
      }
    }

    return SupplierPaymentModel(
      id: row['id'] as String,
      supplierInvoiceId: row['supplier_invoice_id'] as String?,
      invoiceNumber: row['invoice_number'] as String?,
      amountTiyn: (row['amount_tiyn'] as num?)?.toInt() ?? 0,
      method: method,
      paidAt: DateTime.parse(row['paid_at'] as String),
      isReversed: row['status'] == 'reversed',
      reversalOf: row['reversal_of'] as String?,
      comment: row['comment'] as String?,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }
}
