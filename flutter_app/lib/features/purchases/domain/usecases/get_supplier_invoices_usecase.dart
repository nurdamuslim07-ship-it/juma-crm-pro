import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/supplier_invoice.dart';
import '../repositories/purchases_repository.dart';

class GetSupplierInvoicesUseCase {
  const GetSupplierInvoicesUseCase(this._repository);
  final PurchasesRepository _repository;

  Future<Either<Failure, List<SupplierInvoice>>> call(String partnerId) {
    return _repository.getSupplierInvoices(partnerId);
  }
}
