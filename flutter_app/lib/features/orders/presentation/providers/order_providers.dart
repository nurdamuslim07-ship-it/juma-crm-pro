import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/supabase_provider.dart';
import '../../../../core/realtime/table_realtime_provider.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/order_remote_datasource.dart';
import '../../data/repositories/order_repository_impl.dart';
import '../../domain/entities/customer_order.dart';
import '../../domain/repositories/order_repository.dart';
import '../../domain/usecases/delete_order_usecase.dart';
import '../../domain/usecases/get_employee_options_usecase.dart';
import '../../domain/usecases/get_orders_usecase.dart';
import '../../domain/usecases/get_status_role_permissions_usecase.dart';
import '../../domain/usecases/update_order_status_usecase.dart';
import '../../domain/usecases/upsert_order_usecase.dart';
import '../../domain/value_objects/order_status.dart';

final orderRemoteDataSourceProvider = Provider<OrderRemoteDataSource>((ref) {
  return OrderRemoteDataSource(ref.watch(supabaseClientProvider));
});

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepositoryImpl(ref.watch(orderRemoteDataSourceProvider));
});

final getOrdersUseCaseProvider = Provider<GetOrdersUseCase>((ref) {
  return GetOrdersUseCase(ref.watch(orderRepositoryProvider));
});

final upsertOrderUseCaseProvider = Provider<UpsertOrderUseCase>((ref) {
  return UpsertOrderUseCase(ref.watch(orderRepositoryProvider));
});

final updateOrderStatusUseCaseProvider = Provider<UpdateOrderStatusUseCase>((
  ref,
) {
  return UpdateOrderStatusUseCase(ref.watch(orderRepositoryProvider));
});

final deleteOrderUseCaseProvider = Provider<DeleteOrderUseCase>((ref) {
  return DeleteOrderUseCase(ref.watch(orderRepositoryProvider));
});

final getStatusRolePermissionsUseCaseProvider =
    Provider<GetStatusRolePermissionsUseCase>((ref) {
      return GetStatusRolePermissionsUseCase(
        ref.watch(orderRepositoryProvider),
      );
    });

final getEmployeeOptionsUseCaseProvider = Provider<GetEmployeeOptionsUseCase>((
  ref,
) {
  return GetEmployeeOptionsUseCase(ref.watch(orderRepositoryProvider));
});

final orderSearchQueryProvider = StateProvider<String>((ref) => '');

/// `null` = "барлығы" (all statuses).
final orderStatusFilterProvider = StateProvider<OrderStatus?>((ref) => null);

final ordersListProvider = FutureProvider.autoDispose<List<CustomerOrder>>((
  ref,
) {
  final query = ref.watch(orderSearchQueryProvider);
  final statusFilter = ref.watch(orderStatusFilterProvider);
  return ref
      .watch(getOrdersUseCaseProvider)
      .call(searchQuery: query, statusFilter: statusFilter)
      .then(
        (either) => either.match((failure) => throw failure, (data) => data),
      );
});

final orderDetailProvider = FutureProvider.autoDispose
    .family<CustomerOrder, String>((ref, id) {
      return ref
          .watch(orderRepositoryProvider)
          .getOrder(id)
          .then(
            (either) =>
                either.match((failure) => throw failure, (data) => data),
          );
    });

/// Full status→allowed-role-keys map from `order_status_role_permissions`
/// — rarely changes, fetched once per app session.
final statusRolePermissionsProvider =
    FutureProvider<Map<OrderStatus, Set<String>>>((ref) {
      return ref
          .watch(getStatusRolePermissionsUseCaseProvider)
          .call()
          .then(
            (either) =>
                either.match((failure) => throw failure, (data) => data),
          );
    });

/// Statuses the *current* user is allowed to set, per
/// [statusRolePermissionsProvider] cross-referenced against
/// [currentUserProvider]'s roles — UI convenience only (see
/// core/router/app_router.dart's redirect-guard comment for the same
/// caveat): the DB trigger is what actually enforces this regardless
/// of what this provider returns. Empty while the permissions map is
/// still loading, never a crash.
final allowedOrderStatusesProvider = Provider<Set<OrderStatus>>((ref) {
  final user = ref.watch(currentUserProvider);
  final permissionsMap = ref.watch(statusRolePermissionsProvider).valueOrNull;
  if (user == null || permissionsMap == null) return {};
  return computeAllowedOrderStatuses(permissionsMap, user.roleKeys);
});

/// Pure — extracted from [allowedOrderStatusesProvider] so the role-
/// gating logic (mirrors ORDER_WORKFLOW.md's per-status role table and
/// the `orders_status_transition_guard` DB trigger) is unit-testable
/// without spinning up a ProviderContainer.
Set<OrderStatus> computeAllowedOrderStatuses(
  Map<OrderStatus, Set<String>> permissions,
  List<String> userRoleKeys,
) {
  return permissions.entries
      .where((entry) => entry.value.any(userRoleKeys.contains))
      .map((entry) => entry.key)
      .toSet();
}

/// Stage 4 Part 1 — replaces manual pull-to-refresh-only staleness
/// with a live subscription; `OrdersListScreen` activates this by
/// `ref.watch`-ing it once. See `tableRealtimeProvider`'s own doc
/// comment for why this is safe to subscribe to directly (real,
/// non-revoked RLS policy on `orders`).
final ordersRealtimeProvider = tableRealtimeProvider('orders', (ref) {
  ref.invalidate(ordersListProvider);
});
