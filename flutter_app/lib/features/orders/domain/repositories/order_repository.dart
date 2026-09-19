import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/customer_order.dart';
import '../entities/employee_option.dart';
import '../value_objects/order_status.dart';

abstract class OrderRepository {
  Future<Either<Failure, List<CustomerOrder>>> getOrders({
    String? searchQuery,
    OrderStatus? statusFilter,
  });

  Future<Either<Failure, CustomerOrder>> getOrder(String id);

  Future<Either<Failure, CustomerOrder>> createOrder(CustomerOrder order);

  Future<Either<Failure, CustomerOrder>> updateOrder(CustomerOrder order);

  /// Dedicated status-only update — same underlying column write (and
  /// the same DB-level role trigger) as [updateOrder], but a focused
  /// method for the detail screen's quick status-change control so
  /// that action isn't bundled with a full-form submission.
  Future<Either<Failure, CustomerOrder>> updateStatus(
    String orderId,
    OrderStatus newStatus,
  );

  Future<Either<Failure, Unit>> deleteOrder(String id);

  /// The full status→allowed-roles mapping from
  /// `order_status_role_permissions` (see
  /// supabase/migrations/20260713000015_order_status_transitions.sql)
  /// — read once and cross-referenced against the current user's
  /// roles so the UI only *offers* statuses the backend will actually
  /// accept. The DB trigger remains the real enforcement regardless.
  Future<Either<Failure, Map<OrderStatus, Set<String>>>>
  getStatusRolePermissions();

  /// `profiles` projection for the responsible-employee picker (see
  /// [EmployeeOption]'s doc comment for why this isn't the future
  /// Employees module's richer entity).
  Future<Either<Failure, List<EmployeeOption>>> getEmployeeOptions({
    String? searchQuery,
  });
}
