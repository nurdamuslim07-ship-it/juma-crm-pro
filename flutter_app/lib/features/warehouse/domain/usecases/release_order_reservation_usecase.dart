import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../repositories/warehouse_repository.dart';

class ReleaseOrderReservationUseCase {
  const ReleaseOrderReservationUseCase(this._repository);
  final WarehouseRepository _repository;

  Future<Either<Failure, Unit>> call(String reservationId) {
    return _repository.releaseOrderReservation(reservationId);
  }
}
