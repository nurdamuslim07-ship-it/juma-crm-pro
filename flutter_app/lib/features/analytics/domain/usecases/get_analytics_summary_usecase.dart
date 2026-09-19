import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/analytics_summary.dart';
import '../repositories/analytics_repository.dart';

class GetAnalyticsSummaryUseCase {
  const GetAnalyticsSummaryUseCase(this._repository);
  final AnalyticsRepository _repository;

  Future<Either<Failure, AnalyticsSummary>> call({
    required DateTime start,
    required DateTime end,
  }) {
    return _repository.getSummary(start: start, end: end);
  }
}
