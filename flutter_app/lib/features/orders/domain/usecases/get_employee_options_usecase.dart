import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/employee_option.dart';
import '../repositories/order_repository.dart';

class GetEmployeeOptionsUseCase {
  const GetEmployeeOptionsUseCase(this._repository);
  final OrderRepository _repository;

  Future<Either<Failure, List<EmployeeOption>>> call({String? searchQuery}) {
    return _repository.getEmployeeOptions(searchQuery: searchQuery);
  }
}
