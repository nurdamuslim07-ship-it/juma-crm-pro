import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../repositories/purchases_repository.dart';

class ApprovePurchaseOrderUseCase {
  const ApprovePurchaseOrderUseCase(this._repository);
  final PurchasesRepository _repository;

  Future<Either<Failure, Unit>> call(String id) {
    return _repository.approvePurchaseOrder(id);
  }
}
