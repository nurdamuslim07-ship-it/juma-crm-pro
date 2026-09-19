import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/production_stage.dart';
import '../repositories/production_repository.dart';

class GetProductionStagesUseCase {
  const GetProductionStagesUseCase(this._repository);
  final ProductionRepository _repository;

  Future<Either<Failure, List<ProductionStage>>> call() {
    return _repository.getStages();
  }
}
