import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/purchase_order_status.dart';
import '../entities/purchase_order_summary.dart';
import '../repositories/purchases_repository.dart';

class GetPurchaseOrdersUseCase {
  const GetPurchaseOrdersUseCase(this._repository);
  final PurchasesRepository _repository;

  Future<Either<Failure, List<PurchaseOrderSummary>>> call({
    PurchaseOrderStatus? status,
    String? supplierPartnerId,
    String? search,
  }) {
    return _repository.getPurchaseOrders(
      status: status,
      supplierPartnerId: supplierPartnerId,
      search: search,
    );
  }
}
