import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../repositories/purchases_repository.dart';

class MarkPurchaseOrderDeliveredUseCase {
  const MarkPurchaseOrderDeliveredUseCase(this._repository);
  final PurchasesRepository _repository;

  Future<Either<Failure, Unit>> call(String id) {
    return _repository.markPurchaseOrderDelivered(id);
  }
}
