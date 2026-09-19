import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/purchase_analytics.dart';
import '../../domain/entities/purchase_order_detail.dart';
import '../../domain/entities/purchase_order_item.dart';
import '../../domain/entities/purchase_order_status.dart';
import '../../domain/entities/purchase_order_summary.dart';
import '../../domain/entities/supplier_balance.dart';
import '../../domain/entities/supplier_invoice.dart';
import '../../domain/entities/supplier_payment.dart';
import '../../domain/repositories/purchases_repository.dart';
import '../datasources/purchases_remote_datasource.dart';

class PurchasesRepositoryImpl implements PurchasesRepository {
  PurchasesRepositoryImpl(this._remote);
  final PurchasesRemoteDataSource _remote;

  @override
  Future<Either<Failure, List<PurchaseOrderSummary>>> getPurchaseOrders({
    PurchaseOrderStatus? status,
    String? supplierPartnerId,
    String? search,
  }) async {
    try {
      final items = await _remote.getPurchaseOrders(
        status: status,
        supplierPartnerId: supplierPartnerId,
        search: search,
      );
      return right(items);
    } on PostgrestException catch (e) {
      return left(_mapPostgrestError(e));
    } catch (e) {
      return left(mapUnexpectedError(e));
    }
  }

  @override
  Future<Either<Failure, PurchaseOrderDetail>> getPurchaseOrderDetail(
    String id,
  ) async {
    try {
      return right(await _remote.getPurchaseOrderDetail(id));
    } on NotFoundException catch (e) {
      return left(NotFoundFailure(e.message ?? 'Тапсырыс табылмады'));
    } on PostgrestException catch (e) {
      return left(_mapPostgrestError(e));
    } catch (e) {
      return left(mapUnexpectedError(e));
    }
  }

  @override
  Future<Either<Failure, String>> createPurchaseOrder({
    required String orderNumber,
    required String supplierPartnerId,
    required List<PurchaseOrderItem> items,
    String? responsibleEmployeeId,
    DateTime? expectedDeliveryDate,
    int deliveryCostTiyn = 0,
    int vatTiyn = 0,
    int discountTiyn = 0,
    String? comment,
  }) async {
    try {
      final id = await _remote.createPurchaseOrder(
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
      return right(id);
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
  Future<Either<Failure, Unit>> updatePurchaseOrder({
    required String id,
    required String supplierPartnerId,
    required List<PurchaseOrderItem> items,
    String? responsibleEmployeeId,
    DateTime? expectedDeliveryDate,
    int deliveryCostTiyn = 0,
    int vatTiyn = 0,
    int discountTiyn = 0,
    String? comment,
  }) async {
    try {
      await _remote.updatePurchaseOrder(
        id: id,
        supplierPartnerId: supplierPartnerId,
        items: items,
        responsibleEmployeeId: responsibleEmployeeId,
        expectedDeliveryDate: expectedDeliveryDate,
        deliveryCostTiyn: deliveryCostTiyn,
        vatTiyn: vatTiyn,
        discountTiyn: discountTiyn,
        comment: comment,
      );
      return right(unit);
    } on ServerException catch (e) {
      return left(
        ValidationFailure(e.message ?? 'Тапсырысты өңдеу мүмкін емес'),
      );
    } on PostgrestException catch (e) {
      return left(_mapPostgrestError(e));
    } catch (e) {
      return left(mapUnexpectedError(e));
    }
  }

  @override
  Future<Either<Failure, Unit>> approvePurchaseOrder(String id) async {
    try {
      await _remote.approvePurchaseOrder(id);
      return right(unit);
    } on ServerException catch (e) {
      return left(ValidationFailure(e.message ?? 'Бекіту мүмкін емес'));
    } on PostgrestException catch (e) {
      return left(_mapPostgrestError(e));
    } catch (e) {
      return left(mapUnexpectedError(e));
    }
  }

  @override
  Future<Either<Failure, Unit>> rejectPurchaseOrder(
    String id, {
    String? reason,
  }) async {
    try {
      await _remote.rejectPurchaseOrder(id, reason: reason);
      return right(unit);
    } on ServerException catch (e) {
      return left(ValidationFailure(e.message ?? 'Бас тарту мүмкін емес'));
    } on PostgrestException catch (e) {
      return left(_mapPostgrestError(e));
    } catch (e) {
      return left(mapUnexpectedError(e));
    }
  }

  @override
  Future<Either<Failure, Unit>> markPurchaseOrderDelivered(String id) async {
    try {
      await _remote.markPurchaseOrderDelivered(id);
      return right(unit);
    } on ServerException catch (e) {
      return left(
        ValidationFailure(e.message ?? 'Жеткізілді деп белгілеу мүмкін емес'),
      );
    } on PostgrestException catch (e) {
      return left(_mapPostgrestError(e));
    } catch (e) {
      return left(mapUnexpectedError(e));
    }
  }

  @override
  Future<Either<Failure, Unit>> cancelPurchaseOrder(
    String id, {
    String? reason,
  }) async {
    try {
      await _remote.cancelPurchaseOrder(id, reason: reason);
      return right(unit);
    } on ServerException catch (e) {
      return left(ValidationFailure(e.message ?? 'Бас тарту мүмкін емес'));
    } on PostgrestException catch (e) {
      return left(_mapPostgrestError(e));
    } catch (e) {
      return left(mapUnexpectedError(e));
    }
  }

  @override
  Future<Either<Failure, String>> receivePurchaseOrder(String id) async {
    try {
      return right(await _remote.receivePurchaseOrder(id));
    } on ServerException catch (e) {
      return left(ValidationFailure(e.message ?? 'Қабылдау мүмкін емес'));
    } on PostgrestException catch (e) {
      return left(_mapPostgrestError(e));
    } catch (e) {
      return left(mapUnexpectedError(e));
    }
  }

  @override
  Future<Either<Failure, Map<String, num>>>
  getPendingPurchaseQuantities() async {
    try {
      return right(await _remote.getPendingPurchaseQuantities());
    } on PostgrestException catch (e) {
      return left(_mapPostgrestError(e));
    } catch (e) {
      return left(mapUnexpectedError(e));
    }
  }

  @override
  Future<Either<Failure, List<SupplierInvoice>>> getSupplierInvoices(
    String partnerId,
  ) async {
    try {
      return right(await _remote.getSupplierInvoices(partnerId));
    } on PostgrestException catch (e) {
      return left(_mapPostgrestError(e));
    } catch (e) {
      return left(mapUnexpectedError(e));
    }
  }

  @override
  Future<Either<Failure, List<SupplierPayment>>> getSupplierPayments(
    String partnerId,
  ) async {
    try {
      return right(await _remote.getSupplierPayments(partnerId));
    } on PostgrestException catch (e) {
      return left(_mapPostgrestError(e));
    } catch (e) {
      return left(mapUnexpectedError(e));
    }
  }

  @override
  Future<Either<Failure, Unit>> recordSupplierPayment({
    required String partnerId,
    required int amountTiyn,
    required String methodId,
    String? supplierInvoiceId,
    String? cashboxId,
    String? bankAccountId,
    DateTime? paidAt,
    String? comment,
  }) async {
    try {
      await _remote.recordSupplierPayment(
        partnerId: partnerId,
        amountTiyn: amountTiyn,
        methodId: methodId,
        supplierInvoiceId: supplierInvoiceId,
        cashboxId: cashboxId,
        bankAccountId: bankAccountId,
        paidAt: paidAt,
        comment: comment,
      );
      return right(unit);
    } on ServerException catch (e) {
      return left(ValidationFailure(e.message ?? 'Төлемді жазу мүмкін емес'));
    } on PostgrestException catch (e) {
      return left(_mapPostgrestError(e));
    } catch (e) {
      return left(mapUnexpectedError(e));
    }
  }

  @override
  Future<Either<Failure, Unit>> reverseSupplierPayment(
    String paymentId,
    String reason,
  ) async {
    try {
      await _remote.reverseSupplierPayment(paymentId, reason);
      return right(unit);
    } on ServerException catch (e) {
      return left(ValidationFailure(e.message ?? 'Төлем табылмады'));
    } on PostgrestException catch (e) {
      return left(_mapPostgrestError(e));
    } catch (e) {
      return left(mapUnexpectedError(e));
    }
  }

  @override
  Future<Either<Failure, PurchaseAnalytics>> getPurchaseAnalytics() async {
    try {
      return right(await _remote.getPurchaseAnalytics());
    } on PostgrestException catch (e) {
      return left(_mapPostgrestError(e));
    } catch (e) {
      return left(mapUnexpectedError(e));
    }
  }

  @override
  Future<Either<Failure, Map<String, String>>> getPaymentMethodIds() async {
    try {
      final ids = await _remote.getPaymentMethodIds();
      return right(ids.map((method, id) => MapEntry(method.dbKey, id)));
    } on PostgrestException catch (e) {
      return left(_mapPostgrestError(e));
    } catch (e) {
      return left(mapUnexpectedError(e));
    }
  }

  @override
  Future<Either<Failure, SupplierBalance>> getSupplierBalance(
    String partnerId,
  ) async {
    try {
      return right(await _remote.getSupplierBalance(partnerId));
    } on NotFoundException catch (e) {
      return left(NotFoundFailure(e.message ?? 'Серіктес табылмады'));
    } on PostgrestException catch (e) {
      return left(_mapPostgrestError(e));
    } catch (e) {
      return left(mapUnexpectedError(e));
    }
  }

  Failure _mapPostgrestError(PostgrestException e) {
    if (e.code == '42501') return PermissionFailure(e.message);
    if (e.code == 'P0002' || e.code == 'PGRST116') {
      return NotFoundFailure(e.message);
    }
    return ServerFailure(e.message);
  }
}
