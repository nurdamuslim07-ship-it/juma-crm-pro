import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/purchase_analytics.dart';
import '../repositories/purchases_repository.dart';

class GetPurchaseAnalyticsUseCase {
  const GetPurchaseAnalyticsUseCase(this._repository);
  final PurchasesRepository _repository;

  Future<Either<Failure, PurchaseAnalytics>> call() {
    return _repository.getPurchaseAnalytics();
  }
}
