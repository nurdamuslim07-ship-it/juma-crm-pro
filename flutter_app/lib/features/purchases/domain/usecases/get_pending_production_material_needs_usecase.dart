import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import 'get_pending_purchase_quantities_usecase.dart';

/// Alias for [GetPendingPurchaseQuantitiesUseCase] under the
/// requirement's requested name — additive only per the owner's
/// "Тек қосу" decision; the original name/usecase is kept unchanged.
class GetPendingProductionMaterialNeedsUseCase {
  const GetPendingProductionMaterialNeedsUseCase(this._getPendingQuantities);
  final GetPendingPurchaseQuantitiesUseCase _getPendingQuantities;

  Future<Either<Failure, Map<String, num>>> call() {
    return _getPendingQuantities();
  }
}
