import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../repositories/purchases_repository.dart';

class ReverseSupplierPaymentUseCase {
  const ReverseSupplierPaymentUseCase(this._repository);
  final PurchasesRepository _repository;

  Future<Either<Failure, Unit>> call(String paymentId, String reason) {
    return _repository.reverseSupplierPayment(paymentId, reason);
  }
}
