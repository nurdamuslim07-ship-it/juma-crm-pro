import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/payment.dart';
import '../repositories/payment_repository.dart';

class UpdatePaymentUseCase {
  const UpdatePaymentUseCase(this._repository);
  final PaymentRepository _repository;

  Future<Either<Failure, Payment>> call(Payment payment) =>
      _repository.updatePayment(payment);
}
