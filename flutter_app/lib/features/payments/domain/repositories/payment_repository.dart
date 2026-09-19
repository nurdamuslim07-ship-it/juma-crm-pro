import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/payment.dart';
import '../value_objects/payment_method.dart';

abstract class PaymentRepository {
  /// [orderId] narrows to one order's payment history (requirement
  /// #2); omit it for the global Payments tab. [searchQuery] matches
  /// client name/phone, order number, and payment method label
  /// (requirement #16). [methodFilter]/[dateFrom]/[dateTo] back
  /// requirement #15.
  Future<Either<Failure, List<Payment>>> getPayments({
    String? orderId,
    String? searchQuery,
    PaymentMethod? methodFilter,
    DateTime? dateFrom,
    DateTime? dateTo,
  });

  /// Routed through the `record_payment` RPC server-side — this is
  /// what actually enforces the overpayment guard (requirement #12),
  /// not a client-side check alone (that exists too, for immediate
  /// UX feedback, but the server call is the real gate).
  Future<Either<Failure, Payment>> createPayment({
    required String orderId,
    required String clientId,
    required int amountTiyn,
    required PaymentMethod method,
    required DateTime paidAt,
    String? comment,
    String? receiptUrl,
  });

  /// Limited-field edit (requirement #13) — see [Payment]'s doc
  /// comment for exactly which fields the server actually allows to
  /// change; passing a different [Payment.amountTiyn] here is
  /// rejected by the `payments_prevent_tamper` trigger regardless.
  Future<Either<Failure, Payment>> updatePayment(Payment payment);

  Future<Either<Failure, Unit>> deletePayment(String id);

  /// Uploads to the private `receipts` Storage bucket (requirement
  /// #8) and returns the path to store on the payment row.
  Future<Either<Failure, String>> uploadReceipt({
    required List<int> bytes,
    required String fileName,
  });

  /// A signed, time-limited URL to view/download a stored receipt —
  /// the bucket is private, so [Payment.receiptUrl] is a storage path,
  /// not a directly loadable URL.
  Future<Either<Failure, String>> getReceiptSignedUrl(String path);

  /// `payment_methods.key` → row id — resolved once so
  /// [createPayment] can send the FK Postgres expects while the
  /// domain/UI only ever deal in [PaymentMethod].
  Future<Either<Failure, Map<PaymentMethod, String>>> getPaymentMethodIds();
}
