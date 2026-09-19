import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../repositories/order_repository.dart';

class DeleteOrderUseCase {
  const DeleteOrderUseCase(this._repository);
  final OrderRepository _repository;

  Future<Either<Failure, Unit>> call(String id) => _repository.deleteOrder(id);
}
