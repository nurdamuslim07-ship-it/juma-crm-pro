import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/employee_kpi.dart';
import '../repositories/analytics_repository.dart';

class GetEmployeeKpisUseCase {
  const GetEmployeeKpisUseCase(this._repository);
  final AnalyticsRepository _repository;

  Future<Either<Failure, List<EmployeeKpi>>> call({
    required DateTime start,
    required DateTime end,
    String? employeeId,
  }) {
    return _repository.getEmployeeKpis(
      start: start,
      end: end,
      employeeId: employeeId,
    );
  }
}
