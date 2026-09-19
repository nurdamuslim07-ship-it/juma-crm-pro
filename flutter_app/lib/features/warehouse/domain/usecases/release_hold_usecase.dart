import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../repositories/warehouse_repository.dart';

class ReleaseHoldUseCase {
  const ReleaseHoldUseCase(this._repository);
  final WarehouseRepository _repository;

  Future<Either<Failure, Unit>> call(String holdId) {
    return _repository.releaseHold(holdId);
  }
}
