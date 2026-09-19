import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/inventory_hold.dart';
import '../repositories/warehouse_repository.dart';

class GetActiveHoldsUseCase {
  const GetActiveHoldsUseCase(this._repository);
  final WarehouseRepository _repository;

  Future<Either<Failure, List<InventoryHold>>> call(String materialId) {
    return _repository.getActiveHolds(materialId);
  }
}
