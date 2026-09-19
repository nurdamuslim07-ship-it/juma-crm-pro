import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../repositories/purchases_repository.dart';

class RejectPurchaseOrderUseCase {
  const RejectPurchaseOrderUseCase(this._repository);
  final PurchasesRepository _repository;

  Future<Either<Failure, Unit>> call(String id, {String? reason}) {
    return _repository.rejectPurchaseOrder(id, reason: reason);
  }
}
