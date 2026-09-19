import 'dart:math';

import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/exceptions.dart';
import '../../domain/entities/employee_option.dart';
import '../../domain/value_objects/order_status.dart';
import '../models/customer_order_model.dart';

/// See DATABASE_SCHEMA.md "Orders domain". RLS on `orders` already
/// scopes read/write by orders.read/orders.read_all/orders.write and
/// filters `deleted_at`; the role-gated status trigger (see
/// supabase/migrations/20260713000015_order_status_transitions.sql)
/// enforces who may set which status regardless of what this class
/// sends — a rejected transition surfaces here as a PostgrestException
/// with code 42501 and the trigger's own Kazakh message.
class OrderRemoteDataSource {
  OrderRemoteDataSource(this._client);
  final SupabaseClient _client;

  static const _selectWithJoins =
      '*, '
      'client:clients(name, phone), '
      'responsible_employee:profiles!orders_responsible_employee_id_fkey(full_name)';

  Future<List<CustomerOrderModel>> getOrders({
    String? searchQuery,
    OrderStatus? statusFilter,
  }) async {
    var query = _client.from('orders').select(_selectWithJoins);

    if (statusFilter != null) {
      query = query.eq('status', statusFilter.dbValue);
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = searchQuery.trim();
      final matchingClientIds = await _findClientIdsMatching(q);
      final clientFilter = matchingClientIds.isEmpty
          ? ''
          : ',client_id.in.(${matchingClientIds.join(',')})';
      query = query.or(
        'order_number.ilike.%$q%,product_type.ilike.%$q%$clientFilter',
      );
    }

    final rows = await query.order('created_at', ascending: false);
    return _withPaidAmounts(rows as List);
  }

  Future<CustomerOrderModel> getOrder(String id) async {
    final row = await _client
        .from('orders')
        .select(_selectWithJoins)
        .eq('id', id)
        .single();
    final withPaid = await _withPaidAmounts([row]);
    return withPaid.first;
  }

  Future<CustomerOrderModel> createOrder(CustomerOrderModel order) async {
    final userId = _client.auth.currentUser?.id;
    final payload = order.toWriteMap()
      ..['order_number'] = await _generateOrderNumber()
      ..['status'] = OrderStatus.measurement.dbValue
      ..['created_by'] = userId;

    final row = await _client
        .from('orders')
        .insert(payload)
        .select(_selectWithJoins)
        .single();
    final withPaid = await _withPaidAmounts([row]);
    return withPaid.first;
  }

  Future<CustomerOrderModel> updateOrder(CustomerOrderModel order) async {
    final row = await _client
        .from('orders')
        .update(order.toWriteMap())
        .eq('id', order.id)
        .select(_selectWithJoins)
        .single();
    final withPaid = await _withPaidAmounts([row]);
    return withPaid.first;
  }

  Future<CustomerOrderModel> updateStatus(
    String orderId,
    OrderStatus status,
  ) async {
    try {
      final row = await _client
          .from('orders')
          .update({'status': status.dbValue})
          .eq('id', orderId)
          .select(_selectWithJoins)
          .single();
      final withPaid = await _withPaidAmounts([row]);
      return withPaid.first;
    } on PostgrestException catch (e) {
      if (e.code == '42501') {
        throw ServerException(e.message);
      }
      rethrow;
    }
  }

  /// Soft delete only — see DATABASE_SCHEMA.md's soft-delete rule.
  /// Goes through `soft_delete_order()` (SECURITY DEFINER RPC), not a
  /// raw `.update()` — same reason as
  /// ClientRemoteDataSource.deleteClient: a raw update fails RLS
  /// unconditionally, because every orders SELECT policy requires
  /// `deleted_at is null` and Postgres's row-security engine requires
  /// the resulting row to still satisfy a SELECT policy for any
  /// UPDATE, regardless of the UPDATE policy's own WITH CHECK.
  Future<void> deleteOrder(String id) async {
    await _client.rpc('soft_delete_order', params: {'p_order_id': id});
  }

  Future<Map<OrderStatus, Set<String>>> getStatusRolePermissions() async {
    final rows = await _client.from('order_status_role_permissions').select();
    final map = <OrderStatus, Set<String>>{};
    for (final row in rows as List) {
      final status = OrderStatus.fromDbValue(row['status'] as String);
      map.putIfAbsent(status, () => {}).add(row['role_key'] as String);
    }
    return map;
  }

  Future<List<EmployeeOption>> getEmployeeOptions({String? searchQuery}) async {
    var query = _client
        .from('profiles')
        .select('id, full_name, phone')
        .eq('is_active', true);

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      query = query.ilike('full_name', '%${searchQuery.trim()}%');
    }

    final rows = await query.order('full_name');
    return (rows as List)
        .map(
          (row) => EmployeeOption(
            id: row['id'] as String,
            fullName: row['full_name'] as String,
            phone: row['phone'] as String?,
          ),
        )
        .toList();
  }

  Future<List<String>> _findClientIdsMatching(String query) async {
    final rows = await _client
        .from('clients')
        .select('id')
        .or('name.ilike.%$query%,phone.ilike.%$query%');
    return (rows as List).map((r) => r['id'] as String).toList();
  }

  /// Batches a single `payments` query for every order id in [rows]
  /// instead of one query per order — the sum-per-order that backs
  /// [CustomerOrder.paidTiyn] (see that class's doc comment: this is
  /// intentionally never a stored column).
  Future<List<CustomerOrderModel>> _withPaidAmounts(List rows) async {
    if (rows.isEmpty) return [];
    final orderIds = rows
        .map((r) => (r as Map<String, dynamic>)['id'] as String)
        .toList();

    // active_payments (see supabase/migrations/20260713000016_payments_module.sql)
    // already excludes reversed and soft-deleted rows — querying the
    // raw `payments` table filtered to status='confirmed' would
    // double-count a payment that was later reversed.
    final paymentRows = await _client
        .from('active_payments')
        .select('order_id, amount_tiyn')
        .inFilter('order_id', orderIds);

    final paidByOrder = <String, int>{};
    for (final p in paymentRows as List) {
      final orderId = p['order_id'] as String;
      final amount = (p['amount_tiyn'] as num).toInt();
      paidByOrder[orderId] = (paidByOrder[orderId] ?? 0) + amount;
    }

    return rows
        .map(
          (row) => CustomerOrderModel.fromRow(
            row as Map<String, dynamic>,
            paidTiyn: paidByOrder[row['id']] ?? 0,
          ),
        )
        .toList();
  }

  Future<String> _generateOrderNumber() async {
    final datePart = DateFormat('yyMMdd').format(DateTime.now());
    final randomPart = (Random().nextInt(9000) + 1000).toString();
    return 'JU-$datePart-$randomPart';
  }
}
