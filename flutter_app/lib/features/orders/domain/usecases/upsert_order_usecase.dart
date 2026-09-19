import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/customer_order.dart';
import '../repositories/order_repository.dart';

class UpsertOrderUseCase {
  const UpsertOrderUseCase(this._repository);
  final OrderRepository _repository;

  Future<Either<Failure, CustomerOrder>> call(
    CustomerOrder order, {
    required bool isNew,
  }) {
    return isNew
        ? _repository.createOrder(order)
        : _repository.updateOrder(order);
  }
}
