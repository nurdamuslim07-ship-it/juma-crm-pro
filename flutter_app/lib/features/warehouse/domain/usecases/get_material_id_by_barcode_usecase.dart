import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../repositories/warehouse_repository.dart';

class GetMaterialIdByBarcodeUseCase {
  const GetMaterialIdByBarcodeUseCase(this._repository);
  final WarehouseRepository _repository;

  Future<Either<Failure, String?>> call(String barcode) {
    return _repository.getMaterialIdByBarcode(barcode);
  }
}
