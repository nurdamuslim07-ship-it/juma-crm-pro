import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../repositories/production_repository.dart';

class MoveOrderToStageUseCase {
  const MoveOrderToStageUseCase(this._repository);
  final ProductionRepository _repository;

  Future<Either<Failure, Unit>> call({
    required String orderId,
    required String stageId,
    String? comment,
  }) {
    return _repository.moveOrderToStage(
      orderId: orderId,
      stageId: stageId,
      comment: comment,
    );
  }
}
