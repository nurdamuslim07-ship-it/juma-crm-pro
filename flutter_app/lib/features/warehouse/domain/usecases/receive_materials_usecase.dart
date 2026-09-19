import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../repositories/warehouse_repository.dart';

class ReceiveMaterialsUseCase {
  const ReceiveMaterialsUseCase(this._repository);
  final WarehouseRepository _repository;

  Future<Either<Failure, Unit>> call({
    required String materialId,
    required String locationId,
    required num quantity,
    required int costPerUnitTiyn,
    String? batchNumber,
    String? supplierPartnerId,
  }) {
    return _repository.receiveMaterials(
      materialId: materialId,
      locationId: locationId,
      quantity: quantity,
      costPerUnitTiyn: costPerUnitTiyn,
      batchNumber: batchNumber,
      supplierPartnerId: supplierPartnerId,
    );
  }
}
