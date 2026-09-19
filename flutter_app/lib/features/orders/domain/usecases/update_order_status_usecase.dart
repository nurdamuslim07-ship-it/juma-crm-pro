import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/customer_order.dart';
import '../repositories/order_repository.dart';
import '../value_objects/order_status.dart';

class UpdateOrderStatusUseCase {
  const UpdateOrderStatusUseCase(this._repository);
  final OrderRepository _repository;

  Future<Either<Failure, CustomerOrder>> call(
    String orderId,
    OrderStatus status,
  ) {
    return _repository.updateStatus(orderId, status);
  }
}
