import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../repositories/production_repository.dart';

class SetOrderMasterUseCase {
  const SetOrderMasterUseCase(this._repository);
  final ProductionRepository _repository;

  Future<Either<Failure, Unit>> call({
    required String orderId,
    required String masterId,
  }) {
    return _repository.setOrderMaster(orderId: orderId, masterId: masterId);
  }
}
