import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import 'mark_purchase_order_delivered_usecase.dart';

/// Alias for [MarkPurchaseOrderDeliveredUseCase] under the
/// requirement's requested name — additive only per the owner's
/// "Тек қосу" decision; the original name/usecase is kept unchanged.
class MarkPurchaseDeliveredUseCase {
  const MarkPurchaseDeliveredUseCase(this._markDelivered);
  final MarkPurchaseOrderDeliveredUseCase _markDelivered;

  Future<Either<Failure, Unit>> call(String id) {
    return _markDelivered(id);
  }
}
