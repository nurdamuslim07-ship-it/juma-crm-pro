import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/warehouse_location.dart';
import '../repositories/warehouse_repository.dart';

class GetLocationsUseCase {
  const GetLocationsUseCase(this._repository);
  final WarehouseRepository _repository;

  Future<Either<Failure, List<WarehouseLocation>>> call() {
    return _repository.getLocations();
  }
}
