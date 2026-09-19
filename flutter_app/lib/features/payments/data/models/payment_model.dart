import '../../domain/entities/payment.dart';
import '../../domain/value_objects/payment_method.dart';

class PaymentModel extends Payment {
  const PaymentModel({
    required super.id,
    required super.orderId,
    required super.orderNumber,
    required super.clientId,
    required super.clientName,
    required super.amountTiyn,
    required super.method,
    required super.paidAt,
    super.recordedByEmployeeId,
    super.recordedByEmployeeName,
    super.comment,
    super.receiptUrl,
    required super.createdAt,
  });

  factory PaymentModel.fromRow(Map<String, dynamic> row) {
    final order = row['order'] as Map<String, dynamic>?;
    final client = row['client'] as Map<String, dynamic>?;
    final method = row['method'] as Map<String, dynamic>?;
    final recordedEmployee = row['recorded_employee'] as Map<String, dynamic>?;

    return PaymentModel(
      id: row['id'] as String,
      orderId: row['order_id'] as String,
      orderNumber: (order?['order_number'] as String?) ?? '',
      clientId: row['client_id'] as String,
      clientName: (client?['name'] as String?) ?? '',
      amountTiyn: (row['amount_tiyn'] as num).toInt(),
      method: PaymentMethod.fromDbKey((method?['key'] as String?) ?? 'other'),
      paidAt: DateTime.parse(row['paid_at'] as String),
      recordedByEmployeeId: row['recorded_by'] as String?,
      recordedByEmployeeName: recordedEmployee?['full_name'] as String?,
      comment: row['comment'] as String?,
      receiptUrl: row['receipt_url'] as String?,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }

  /// Fields the `payments_prevent_tamper` trigger actually allows to
  /// change via a plain UPDATE — see [Payment]'s doc comment.
  Map<String, dynamic> toLimitedUpdateMap({required String methodRowId}) {
    return {
      'method_id': methodRowId,
      'paid_at': paidAt.toIso8601String().substring(0, 10),
      'comment': comment,
      'receipt_url': receiptUrl,
    };
  }
}
