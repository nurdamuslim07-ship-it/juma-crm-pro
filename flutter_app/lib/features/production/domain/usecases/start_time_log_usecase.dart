import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../repositories/production_repository.dart';

class StartTimeLogUseCase {
  const StartTimeLogUseCase(this._repository);
  final ProductionRepository _repository;

  Future<Either<Failure, String>> call({
    required String orderId,
    String? stageId,
  }) {
    return _repository.startTimeLog(orderId: orderId, stageId: stageId);
  }
}
