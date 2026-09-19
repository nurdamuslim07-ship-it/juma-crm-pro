import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/warehouse_summary.dart';
import '../repositories/warehouse_repository.dart';

class GetWarehouseSummaryUseCase {
  const GetWarehouseSummaryUseCase(this._repository);
  final WarehouseRepository _repository;

  Future<Either<Failure, WarehouseSummary>> call() {
    return _repository.getWarehouseSummary();
  }
}
