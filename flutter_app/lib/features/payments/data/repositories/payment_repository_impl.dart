import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show PostgrestException, StorageException;

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/payment.dart';
import '../../domain/repositories/payment_repository.dart';
import '../../domain/value_objects/payment_method.dart';
import '../datasources/payment_remote_datasource.dart';
import '../models/payment_model.dart';

class PaymentRepositoryImpl implements PaymentRepository {
  PaymentRepositoryImpl(this._remote);
  final PaymentRemoteDataSource _remote;

  @override
  Future<Either<Failure, List<Payment>>> getPayments({
    String? orderId,
    String? searchQuery,
    PaymentMethod? methodFilter,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    try {
      final payments = await _remote.getPayments(
        orderId: orderId,
        searchQuery: searchQuery,
        methodFilter: methodFilter,
        dateFrom: dateFrom,
        dateTo: dateTo,
      );
      return right(payments);
    } on PostgrestException catch (e) {
      return left(_mapPostgrestError(e));
    } catch (e) {
      return left(mapUnexpectedError(e));
    }
  }

  @override
  Future<Either<Failure, Payment>> createPayment({
    required String orderId,
    required String clientId,
    required int amountTiyn,
    required PaymentMethod method,
    required DateTime paidAt,
    String? comment,
    String? receiptUrl,
  }) async {
    try {
      final payment = await _remote.createPayment(
        orderId: orderId,
        clientId: clientId,
        amountTiyn: amountTiyn,
        method: method,
        paidAt: paidAt,
        comment: comment,
        receiptUrl: receiptUrl,
      );
      return right(payment);
    } on ServerException catch (e) {
      final message = e.message ?? '';
      if (message.contains('Артық төлем')) {
        return left(ValidationFailure(message));
      }
      return left(
        message.isEmpty
            ? const PermissionFailure()
            : PermissionFailure(message),
      );
    } on PostgrestException catch (e) {
      return left(_mapPostgrestError(e));
    } catch (e) {
      return left(mapUnexpectedError(e));
    }
  }

  @override
  Future<Either<Failure, Payment>> updatePayment(Payment payment) async {
    try {
      final updated = await _remote.updatePayment(_toModel(payment));
      return right(updated);
    } on ServerException catch (e) {
      return left(
        e.message == null
            ? const PermissionFailure()
            : PermissionFailure(e.message!),
      );
    } on PostgrestException catch (e) {
      return left(_mapPostgrestError(e));
    } catch (e) {
      return left(mapUnexpectedError(e));
    }
  }

  @override
  Future<Either<Failure, Unit>> deletePayment(String id) async {
    try {
      await _remote.deletePayment(id);
      return right(unit);
    } on PostgrestException catch (e) {
      return left(_mapPostgrestError(e));
    } catch (e) {
      return left(mapUnexpectedError(e));
    }
  }

  @override
  Future<Either<Failure, String>> uploadReceipt({
    required List<int> bytes,
    required String fileName,
  }) async {
    try {
      final path = await _remote.uploadReceipt(
        bytes: bytes,
        fileName: fileName,
      );
      return right(path);
    } on StorageException catch (e) {
      return left(ServerFailure(e.message));
    } catch (e) {
      return left(mapUnexpectedError(e));
    }
  }

  @override
  Future<Either<Failure, String>> getReceiptSignedUrl(String path) async {
    try {
      final url = await _remote.getReceiptSignedUrl(path);
      return right(url);
    } on StorageException catch (e) {
      return left(ServerFailure(e.message));
    } catch (e) {
      return left(mapUnexpectedError(e));
    }
  }

  @override
  Future<Either<Failure, Map<PaymentMethod, String>>>
  getPaymentMethodIds() async {
    try {
      final map = await _remote.getPaymentMethodIds();
      return right(map);
    } catch (e) {
      return left(mapUnexpectedError(e));
    }
  }

  PaymentModel _toModel(Payment payment) => PaymentModel(
    id: payment.id,
    orderId: payment.orderId,
    orderNumber: payment.orderNumber,
    clientId: payment.clientId,
    clientName: payment.clientName,
    amountTiyn: payment.amountTiyn,
    method: payment.method,
    paidAt: payment.paidAt,
    recordedByEmployeeId: payment.recordedByEmployeeId,
    recordedByEmployeeName: payment.recordedByEmployeeName,
    comment: payment.comment,
    receiptUrl: payment.receiptUrl,
    createdAt: payment.createdAt,
  );

  Failure _mapPostgrestError(PostgrestException e) {
    if (e.code == '42501') return PermissionFailure(e.message);
    if (e.code == '23514') return ValidationFailure(e.message);
    if (e.code == 'PGRST116') return const NotFoundFailure();
    return ServerFailure(e.message);
  }
}
