import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/dashboard_summary.dart';

abstract class DashboardRepository {
  Future<Either<Failure, DashboardSummary>> getSummary();
}
