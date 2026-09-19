import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../repositories/payment_repository.dart';

class DeletePaymentUseCase {
  const DeletePaymentUseCase(this._repository);
  final PaymentRepository _repository;

  Future<Either<Failure, Unit>> call(String id) =>
      _repository.deletePayment(id);
}
