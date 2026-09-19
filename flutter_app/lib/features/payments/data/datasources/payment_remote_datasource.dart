import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/exceptions.dart';
import '../../domain/value_objects/payment_method.dart';
import '../models/payment_model.dart';

/// See DATABASE_SCHEMA.md "Payments & finance" and
/// supabase/migrations/20260713000016_payments_module.sql. Payments
/// are created exclusively through the `record_payment` RPC (never a
/// raw insert) so the server-side overpayment guard always runs.
class PaymentRemoteDataSource {
  PaymentRemoteDataSource(this._client);
  final SupabaseClient _client;

  static const _selectWithJoins =
      '*, '
      'order:orders(order_number), '
      'client:clients(name), '
      'method:payment_methods(key), '
      'recorded_employee:profiles!payments_recorded_by_fkey(full_name)';

  static const Map<String, String> _methodSearchLabelsKk = {
    'cash': 'қолма-қол',
    'kaspi': 'kaspi',
    'bank_transfer': 'банк аударымы',
    'card': 'карта',
    'other': 'басқа',
  };

  Future<List<PaymentModel>> getPayments({
    String? orderId,
    String? searchQuery,
    PaymentMethod? methodFilter,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    var query = _client.from('payments').select(_selectWithJoins);

    if (orderId != null) {
      query = query.eq('order_id', orderId);
    }
    if (methodFilter != null) {
      final methodIds = await getPaymentMethodIds();
      final id = methodIds[methodFilter];
      if (id != null) query = query.eq('method_id', id);
    }
    if (dateFrom != null) {
      query = query.gte('paid_at', _dateOnly(dateFrom));
    }
    if (dateTo != null) {
      query = query.lte('paid_at', _dateOnly(dateTo));
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = searchQuery.trim();
      final orderIds = await _findOrderIdsMatching(q);
      final methodIds = await _findMethodIdsMatching(q);

      if (orderIds.isEmpty && methodIds.isEmpty) return [];

      final clauses = [
        if (orderIds.isNotEmpty) 'order_id.in.(${orderIds.join(',')})',
        if (methodIds.isNotEmpty) 'method_id.in.(${methodIds.join(',')})',
      ];
      query = query.or(clauses.join(','));
    }

    final rows = await query.order('paid_at', ascending: false);
    return (rows as List)
        .map((row) => PaymentModel.fromRow(row as Map<String, dynamic>))
        .toList();
  }

  Future<PaymentModel> createPayment({
    required String orderId,
    required String clientId,
    required int amountTiyn,
    required PaymentMethod method,
    required DateTime paidAt,
    String? comment,
    String? receiptUrl,
  }) async {
    final methodIds = await getPaymentMethodIds();
    final methodId = methodIds[method];
    if (methodId == null) {
      throw const ServerException('Төлем түрі табылмады');
    }

    try {
      final result = await _client.rpc(
        'record_payment',
        params: {
          'p_idempotency_key': _generateIdempotencyKey(),
          'p_order_id': orderId,
          'p_client_id': clientId,
          'p_amount_tiyn': amountTiyn,
          'p_method_id': methodId,
          'p_comment': comment,
          'p_paid_at': _dateOnly(paidAt),
        },
      );
      final row = Map<String, dynamic>.from(result as Map);
      if (receiptUrl != null) {
        return updatePaymentFields(row['id'] as String, {
          'receipt_url': receiptUrl,
        });
      }
      return _hydrate(row);
    } on PostgrestException catch (e) {
      if (e.code == '23514') {
        throw ServerException(e.message);
      }
      if (e.code == '42501') {
        throw ServerException(e.message);
      }
      rethrow;
    }
  }

  Future<PaymentModel> updatePayment(PaymentModel payment) async {
    final methodIds = await getPaymentMethodIds();
    final methodId = methodIds[payment.method];
    if (methodId == null) {
      throw const ServerException('Төлем түрі табылмады');
    }
    return updatePaymentFields(
      payment.id,
      payment.toLimitedUpdateMap(methodRowId: methodId),
    );
  }

  Future<PaymentModel> updatePaymentFields(
    String id,
    Map<String, dynamic> fields,
  ) async {
    try {
      final row = await _client
          .from('payments')
          .update(fields)
          .eq('id', id)
          .select(_selectWithJoins)
          .single();
      return PaymentModel.fromRow(row);
    } on PostgrestException catch (e) {
      if (e.code == '42501') throw ServerException(e.message);
      rethrow;
    }
  }

  /// Soft delete only — same pattern as clients/orders. Excluded from
  /// `active_payments` immediately (see that view's definition), so a
  /// deleted payment stops counting toward the order's paid total.
  Future<void> deletePayment(String id) async {
    await _client
        .from('payments')
        .update({'deleted_at': DateTime.now().toIso8601String()})
        .eq('id', id);
  }

  Future<String> uploadReceipt({
    required List<int> bytes,
    required String fileName,
  }) async {
    final userId = _client.auth.currentUser?.id ?? 'unknown';
    final path = '$userId/${DateTime.now().millisecondsSinceEpoch}-$fileName';
    await _client.storage
        .from('receipts')
        .uploadBinary(path, Uint8List.fromList(bytes));
    return path;
  }

  Future<String> getReceiptSignedUrl(String path) async {
    return _client.storage.from('receipts').createSignedUrl(path, 60 * 10);
  }

  Future<Map<PaymentMethod, String>> getPaymentMethodIds() async {
    // Refresh under the current session: lookups can be provisioned later,
    // and the same datasource can outlive a company/session change.
    final rows = await _client.from('payment_methods').select('id, key');
    final map = <PaymentMethod, String>{};
    for (final row in rows as List) {
      try {
        final method = PaymentMethod.fromDbKey(row['key'] as String);
        map[method] = row['id'] as String;
      } on ArgumentError {
        // Ignore any future method key the app doesn't model yet.
      }
    }
    return map;
  }

  Future<PaymentModel> _hydrate(Map<String, dynamic> row) async {
    final full = await _client
        .from('payments')
        .select(_selectWithJoins)
        .eq('id', row['id'] as String)
        .single();
    return PaymentModel.fromRow(full);
  }

  Future<List<String>> _findOrderIdsMatching(String query) async {
    final byNumber = await _client
        .from('orders')
        .select('id')
        .ilike('order_number', '%$query%');

    final matchingClients = await _client
        .from('clients')
        .select('id')
        .or('name.ilike.%$query%,phone.ilike.%$query%');
    final clientIds = (matchingClients as List)
        .map((r) => r['id'] as String)
        .toList();

    var byClient = <dynamic>[];
    if (clientIds.isNotEmpty) {
      byClient = await _client
          .from('orders')
          .select('id')
          .inFilter('client_id', clientIds);
    }

    return {
      ...(byNumber as List).map((r) => r['id'] as String),
      ...byClient.map((r) => (r as Map<String, dynamic>)['id'] as String),
    }.toList();
  }

  Future<List<String>> _findMethodIdsMatching(String query) async {
    final q = query.toLowerCase();
    final matchingKeys = _methodSearchLabelsKk.entries
        .where((entry) => entry.value.contains(q))
        .map((entry) => entry.key)
        .toSet();
    if (matchingKeys.isEmpty) return [];

    final methodIds = await getPaymentMethodIds();
    return methodIds.entries
        .where((entry) => matchingKeys.contains(entry.key.dbKey))
        .map((entry) => entry.value)
        .toList();
  }

  String _dateOnly(DateTime date) => date.toIso8601String().substring(0, 10);

  String _generateIdempotencyKey() {
    final userId = _client.auth.currentUser?.id ?? 'anon';
    return 'payment-$userId-${DateTime.now().microsecondsSinceEpoch}';
  }
}
