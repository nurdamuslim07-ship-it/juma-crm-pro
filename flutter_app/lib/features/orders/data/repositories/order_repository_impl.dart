import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/customer_order.dart';
import '../../domain/entities/employee_option.dart';
import '../../domain/repositories/order_repository.dart';
import '../../domain/value_objects/order_status.dart';
import '../datasources/order_remote_datasource.dart';
import '../models/customer_order_model.dart';

class OrderRepositoryImpl implements OrderRepository {
  OrderRepositoryImpl(this._remote);
  final OrderRemoteDataSource _remote;

  @override
  Future<Either<Failure, List<CustomerOrder>>> getOrders({
    String? searchQuery,
    OrderStatus? statusFilter,
  }) async {
    try {
      final orders = await _remote.getOrders(
        searchQuery: searchQuery,
        statusFilter: statusFilter,
      );
      return right(orders);
    } on PostgrestException catch (e) {
      return left(_mapPostgrestError(e));
    } catch (e) {
      return left(mapUnexpectedError(e));
    }
  }

  @override
  Future<Either<Failure, CustomerOrder>> getOrder(String id) async {
    try {
      final order = await _remote.getOrder(id);
      return right(order);
    } on PostgrestException catch (e) {
      return left(_mapPostgrestError(e));
    } catch (e) {
      return left(mapUnexpectedError(e));
    }
  }

  @override
  Future<Either<Failure, CustomerOrder>> createOrder(
    CustomerOrder order,
  ) async {
    try {
      final created = await _remote.createOrder(_toModel(order));
      return right(created);
    } on PostgrestException catch (e) {
      return left(_mapPostgrestError(e));
    } catch (e) {
      return left(mapUnexpectedError(e));
    }
  }

  @override
  Future<Either<Failure, CustomerOrder>> updateOrder(
    CustomerOrder order,
  ) async {
    try {
      final updated = await _remote.updateOrder(_toModel(order));
      return right(updated);
    } on PostgrestException catch (e) {
      return left(_mapPostgrestError(e));
    } catch (e) {
      return left(mapUnexpectedError(e));
    }
  }

  @override
  Future<Either<Failure, CustomerOrder>> updateStatus(
    String orderId,
    OrderStatus newStatus,
  ) async {
    try {
      final updated = await _remote.updateStatus(orderId, newStatus);
      return right(updated);
    } on ServerException catch (e) {
      // The role-gated status trigger raises with the exact Kazakh
      // message it wants shown — pass it through as-is rather than
      // wrapping in PermissionFailure's generic default text.
      return left(
        PermissionFailure(e.message ?? 'Бұл әрекетке рұқсатыңыз жоқ'),
      );
    } on PostgrestException catch (e) {
      return left(_mapPostgrestError(e));
    } catch (e) {
      return left(mapUnexpectedError(e));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteOrder(String id) async {
    try {
      await _remote.deleteOrder(id);
      return right(unit);
    } on PostgrestException catch (e) {
      return left(_mapPostgrestError(e));
    } catch (e) {
      return left(mapUnexpectedError(e));
    }
  }

  @override
  Future<Either<Failure, Map<OrderStatus, Set<String>>>>
  getStatusRolePermissions() async {
    try {
      final map = await _remote.getStatusRolePermissions();
      return right(map);
    } catch (e) {
      return left(mapUnexpectedError(e));
    }
  }

  @override
  Future<Either<Failure, List<EmployeeOption>>> getEmployeeOptions({
    String? searchQuery,
  }) async {
    try {
      final options = await _remote.getEmployeeOptions(
        searchQuery: searchQuery,
      );
      return right(options);
    } catch (e) {
      return left(mapUnexpectedError(e));
    }
  }

  CustomerOrderModel _toModel(CustomerOrder order) => CustomerOrderModel(
    id: order.id,
    orderNumber: order.orderNumber,
    clientId: order.clientId,
    clientName: order.clientName,
    clientPhone: order.clientPhone,
    productType: order.productType,
    description: order.description,
    status: order.status,
    responsibleEmployeeId: order.responsibleEmployeeId,
    responsibleEmployeeName: order.responsibleEmployeeName,
    measurementDate: order.measurementDate,
    plannedCompletionDate: order.plannedCompletionDate,
    totalAmountTiyn: order.totalAmountTiyn,
    paidTiyn: order.paidTiyn,
    createdAt: order.createdAt,
  );

  Failure _mapPostgrestError(PostgrestException e) {
    if (e.code == '42501') return PermissionFailure(e.message);
    if (e.code == 'PGRST116') return const NotFoundFailure();
    return ServerFailure(e.message);
  }
}
