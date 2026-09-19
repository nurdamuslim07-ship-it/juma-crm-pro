import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/payment.dart';
import '../repositories/payment_repository.dart';
import '../value_objects/payment_method.dart';

class GetPaymentsUseCase {
  const GetPaymentsUseCase(this._repository);
  final PaymentRepository _repository;

  Future<Either<Failure, List<Payment>>> call({
    String? orderId,
    String? searchQuery,
    PaymentMethod? methodFilter,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) {
    return _repository.getPayments(
      orderId: orderId,
      searchQuery: searchQuery,
      methodFilter: methodFilter,
      dateFrom: dateFrom,
      dateTo: dateTo,
    );
  }
}
