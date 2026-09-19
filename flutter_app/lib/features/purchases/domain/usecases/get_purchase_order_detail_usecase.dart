import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/purchase_order_detail.dart';
import '../repositories/purchases_repository.dart';

class GetPurchaseOrderDetailUseCase {
  const GetPurchaseOrderDetailUseCase(this._repository);
  final PurchasesRepository _repository;

  Future<Either<Failure, PurchaseOrderDetail>> call(String id) {
    return _repository.getPurchaseOrderDetail(id);
  }
}
