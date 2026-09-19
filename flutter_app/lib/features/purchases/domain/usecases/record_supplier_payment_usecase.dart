import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../purchase_validation.dart';
import '../repositories/purchases_repository.dart';

class RecordSupplierPaymentUseCase {
  const RecordSupplierPaymentUseCase(this._repository);
  final PurchasesRepository _repository;

  /// [invoiceRemainingTiyn] is optional and purely additive: pass it
  /// (the invoice's `amountTiyn - paidAmountTiyn`) when this payment is
  /// tied to a specific invoice the caller already has loaded, to
  /// reject an over-payment against THAT invoice client-side before
  /// the round trip. Omit it (as every existing call site does) for a
  /// reason-less advance, which has no upper bound by design — see
  /// `validatePaymentAmount()`.
  Future<Either<Failure, Unit>> call({
    required String partnerId,
    required int amountTiyn,
    required String methodId,
    String? supplierInvoiceId,
    String? cashboxId,
    String? bankAccountId,
    DateTime? paidAt,
    String? comment,
    int? invoiceRemainingTiyn,
  }) {
    final error = validatePaymentAmount(
      amountTiyn: amountTiyn,
      invoiceRemainingTiyn: invoiceRemainingTiyn,
    );
    if (error != null) {
      return Future.value(left(ValidationFailure(error)));
    }

    return _repository.recordSupplierPayment(
      partnerId: partnerId,
      amountTiyn: amountTiyn,
      methodId: methodId,
      supplierInvoiceId: supplierInvoiceId,
      cashboxId: cashboxId,
      bankAccountId: bankAccountId,
      paidAt: paidAt,
      comment: comment,
    );
  }
}
