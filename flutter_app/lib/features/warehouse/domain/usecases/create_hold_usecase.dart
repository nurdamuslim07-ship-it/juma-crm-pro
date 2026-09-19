import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../repositories/warehouse_repository.dart';

class CreateHoldUseCase {
  const CreateHoldUseCase(this._repository);
  final WarehouseRepository _repository;

  Future<Either<Failure, String>> call({
    required String materialId,
    required String locationId,
    required num quantity,
    String? reason,
  }) {
    return _repository.createHold(
      materialId: materialId,
      locationId: locationId,
      quantity: quantity,
      reason: reason,
    );
  }
}
