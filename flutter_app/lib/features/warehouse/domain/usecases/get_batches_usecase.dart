import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/inventory_batch.dart';
import '../repositories/warehouse_repository.dart';

class GetBatchesUseCase {
  const GetBatchesUseCase(this._repository);
  final WarehouseRepository _repository;

  Future<Either<Failure, List<InventoryBatch>>> call(String materialId) {
    return _repository.getBatches(materialId);
  }
}
