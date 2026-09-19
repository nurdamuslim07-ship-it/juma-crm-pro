import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/production_detail.dart';
import '../repositories/production_repository.dart';

class GetOrderProductionDetailUseCase {
  const GetOrderProductionDetailUseCase(this._repository);
  final ProductionRepository _repository;

  Future<Either<Failure, ProductionDetail>> call(String orderId) {
    return _repository.getOrderDetail(orderId);
  }
}
