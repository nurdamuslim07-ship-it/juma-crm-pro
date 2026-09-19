import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../repositories/order_repository.dart';
import '../value_objects/order_status.dart';

class GetStatusRolePermissionsUseCase {
  const GetStatusRolePermissionsUseCase(this._repository);
  final OrderRepository _repository;

  Future<Either<Failure, Map<OrderStatus, Set<String>>>> call() {
    return _repository.getStatusRolePermissions();
  }
}
