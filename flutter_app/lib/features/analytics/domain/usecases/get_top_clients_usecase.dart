import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/top_client.dart';
import '../repositories/analytics_repository.dart';

class GetTopClientsUseCase {
  const GetTopClientsUseCase(this._repository);
  final AnalyticsRepository _repository;

  Future<Either<Failure, List<TopClient>>> call({
    required DateTime start,
    required DateTime end,
    int limit = 10,
  }) {
    return _repository.getTopClients(start: start, end: end, limit: limit);
  }
}
