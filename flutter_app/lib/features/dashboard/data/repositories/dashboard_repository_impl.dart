import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/dashboard_summary.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../datasources/dashboard_remote_datasource.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  DashboardRepositoryImpl(this._remote);
  final DashboardRemoteDataSource _remote;

  @override
  Future<Either<Failure, DashboardSummary>> getSummary() async {
    try {
      final summary = await _remote.getSummary();
      return right(summary);
    } catch (e) {
      return left(mapUnexpectedError(e));
    }
  }
}
