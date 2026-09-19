import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/production_queue_item.dart';
import '../repositories/production_repository.dart';

class GetProductionQueueUseCase {
  const GetProductionQueueUseCase(this._repository);
  final ProductionRepository _repository;

  Future<Either<Failure, List<ProductionQueueItem>>> call({
    String? stageId,
    String? masterId,
    String? search,
  }) {
    return _repository.getQueue(
      stageId: stageId,
      masterId: masterId,
      search: search,
    );
  }
}
