import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../repositories/production_repository.dart';

class StopTimeLogUseCase {
  const StopTimeLogUseCase(this._repository);
  final ProductionRepository _repository;

  Future<Either<Failure, Unit>> call(String logId) {
    return _repository.stopTimeLog(logId);
  }
}
