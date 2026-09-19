import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/material_stock.dart';
import '../repositories/warehouse_repository.dart';

class GetMaterialsUseCase {
  const GetMaterialsUseCase(this._repository);
  final WarehouseRepository _repository;

  Future<Either<Failure, List<MaterialStock>>> call({
    String? categoryId,
    String? search,
    bool lowStockOnly = false,
  }) {
    return _repository.getMaterials(
      categoryId: categoryId,
      search: search,
      lowStockOnly: lowStockOnly,
    );
  }
}
