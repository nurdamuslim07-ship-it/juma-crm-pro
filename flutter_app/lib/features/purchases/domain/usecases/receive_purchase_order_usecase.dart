import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../repositories/purchases_repository.dart';

class ReceivePurchaseOrderUseCase {
  const ReceivePurchaseOrderUseCase(this._repository);
  final PurchasesRepository _repository;

  Future<Either<Failure, String>> call(String id) {
    return _repository.receivePurchaseOrder(id);
  }
}
