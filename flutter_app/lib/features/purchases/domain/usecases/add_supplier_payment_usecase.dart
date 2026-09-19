import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import 'record_supplier_payment_usecase.dart';

/// Alias for [RecordSupplierPaymentUseCase] under the requirement's
/// requested name — additive only per the owner's "Тек қосу" decision;
/// the original name/usecase (and its validation) is kept unchanged.
class AddSupplierPaymentUseCase {
  const AddSupplierPaymentUseCase(this._recordSupplierPayment);
  final RecordSupplierPaymentUseCase _recordSupplierPayment;

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
    return _recordSupplierPayment(
      partnerId: partnerId,
      amountTiyn: amountTiyn,
      methodId: methodId,
      supplierInvoiceId: supplierInvoiceId,
      cashboxId: cashboxId,
      bankAccountId: bankAccountId,
      paidAt: paidAt,
      comment: comment,
      invoiceRemainingTiyn: invoiceRemainingTiyn,
    );
  }
}
