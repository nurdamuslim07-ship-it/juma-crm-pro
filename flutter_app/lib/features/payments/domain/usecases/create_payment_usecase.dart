import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/payment.dart';
import '../repositories/payment_repository.dart';
import '../value_objects/payment_method.dart';

class CreatePaymentUseCase {
  const CreatePaymentUseCase(this._repository);
  final PaymentRepository _repository;

  Future<Either<Failure, Payment>> call({
    required String orderId,
    required String clientId,
    required int amountTiyn,
    required PaymentMethod method,
    required DateTime paidAt,
    String? comment,
    String? receiptUrl,
  }) {
    return _repository.createPayment(
      orderId: orderId,
      clientId: clientId,
      amountTiyn: amountTiyn,
      method: method,
      paidAt: paidAt,
      comment: comment,
      receiptUrl: receiptUrl,
    );
  }
}
