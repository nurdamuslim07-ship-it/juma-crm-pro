import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/production_master.dart';
import '../repositories/production_repository.dart';

class GetMastersUseCase {
  const GetMastersUseCase(this._repository);
  final ProductionRepository _repository;

  Future<Either<Failure, List<ProductionMaster>>> call() {
    return _repository.getMasters();
  }
}
