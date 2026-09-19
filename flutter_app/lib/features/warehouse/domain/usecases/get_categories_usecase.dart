import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/material_category.dart';
import '../repositories/warehouse_repository.dart';

class GetCategoriesUseCase {
  const GetCategoriesUseCase(this._repository);
  final WarehouseRepository _repository;

  Future<Either<Failure, List<MaterialCategory>>> call() {
    return _repository.getCategories();
  }
}
