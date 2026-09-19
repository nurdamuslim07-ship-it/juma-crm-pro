import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../repositories/purchases_repository.dart';

class GetPaymentMethodIdsUseCase {
  const GetPaymentMethodIdsUseCase(this._repository);
  final PurchasesRepository _repository;

  Future<Either<Failure, Map<String, String>>> call() {
    return _repository.getPaymentMethodIds();
  }
}
