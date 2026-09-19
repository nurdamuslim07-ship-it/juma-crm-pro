import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/supplier_balance.dart';
import '../repositories/purchases_repository.dart';

class GetSupplierBalanceUseCase {
  const GetSupplierBalanceUseCase(this._repository);
  final PurchasesRepository _repository;

  Future<Either<Failure, SupplierBalance>> call(String partnerId) {
    return _repository.getSupplierBalance(partnerId);
  }
}
