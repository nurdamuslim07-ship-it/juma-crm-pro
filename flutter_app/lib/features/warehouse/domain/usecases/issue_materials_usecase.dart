import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/cart_item.dart';
import '../repositories/warehouse_repository.dart';

class IssueMaterialsUseCase {
  const IssueMaterialsUseCase(this._repository);
  final WarehouseRepository _repository;

  Future<Either<Failure, Unit>> call({
    required List<CartItem> items,
    String? orderId,
  }) {
    return _repository.issueMaterials(items: items, orderId: orderId);
  }
}
