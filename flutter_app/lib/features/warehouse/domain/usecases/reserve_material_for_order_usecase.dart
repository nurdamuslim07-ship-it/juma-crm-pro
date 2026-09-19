import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../repositories/warehouse_repository.dart';

class ReserveMaterialForOrderUseCase {
  const ReserveMaterialForOrderUseCase(this._repository);
  final WarehouseRepository _repository;

  Future<Either<Failure, String>> call({
    required String orderId,
    required String materialId,
    required num quantity,
    String? locationId,
  }) {
    return _repository.reserveMaterialForOrder(
      orderId: orderId,
      materialId: materialId,
      quantity: quantity,
      locationId: locationId,
    );
  }
}
