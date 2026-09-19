import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/purchase_order_item.dart';
import '../purchase_validation.dart';
import '../repositories/purchases_repository.dart';

class CreatePurchaseOrderUseCase {
  const CreatePurchaseOrderUseCase(this._repository);
  final PurchasesRepository _repository;

  Future<Either<Failure, String>> call({
    required String orderNumber,
    required String supplierPartnerId,
    required List<PurchaseOrderItem> items,
    String? responsibleEmployeeId,
    DateTime? expectedDeliveryDate,
    int deliveryCostTiyn = 0,
    int vatTiyn = 0,
    int discountTiyn = 0,
    String? comment,
  }) {
    final error = validatePurchaseOrderInput(
      supplierPartnerId: supplierPartnerId,
      items: items,
      deliveryCostTiyn: deliveryCostTiyn,
      vatTiyn: vatTiyn,
      discountTiyn: discountTiyn,
    );
    if (error != null) {
      return Future.value(left(ValidationFailure(error)));
    }

    return _repository.createPurchaseOrder(
      orderNumber: orderNumber,
      supplierPartnerId: supplierPartnerId,
      items: items,
      responsibleEmployeeId: responsibleEmployeeId,
      expectedDeliveryDate: expectedDeliveryDate,
      deliveryCostTiyn: deliveryCostTiyn,
      vatTiyn: vatTiyn,
      discountTiyn: discountTiyn,
      comment: comment,
    );
  }
}
