import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/customer_order.dart';
import '../repositories/order_repository.dart';
import '../value_objects/order_status.dart';

class GetOrdersUseCase {
  const GetOrdersUseCase(this._repository);
  final OrderRepository _repository;

  Future<Either<Failure, List<CustomerOrder>>> call({
    String? searchQuery,
    OrderStatus? statusFilter,
  }) {
    return _repository.getOrders(
      searchQuery: searchQuery,
      statusFilter: statusFilter,
    );
  }
}
