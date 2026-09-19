import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/supplier_payment.dart';
import '../repositories/purchases_repository.dart';

class GetSupplierPaymentsUseCase {
  const GetSupplierPaymentsUseCase(this._repository);
  final PurchasesRepository _repository;

  Future<Either<Failure, List<SupplierPayment>>> call(String partnerId) {
    return _repository.getSupplierPayments(partnerId);
  }
}
