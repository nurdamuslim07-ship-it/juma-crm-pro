import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../repositories/purchases_repository.dart';

class GetPendingPurchaseQuantitiesUseCase {
  const GetPendingPurchaseQuantitiesUseCase(this._repository);
  final PurchasesRepository _repository;

  Future<Either<Failure, Map<String, num>>> call() {
    return _repository.getPendingPurchaseQuantities();
  }
}
