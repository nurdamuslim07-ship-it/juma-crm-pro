import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/exceptions.dart';
import '../../../payments/domain/value_objects/payment_method.dart';
import '../../domain/entities/purchase_order_item.dart';
import '../../domain/entities/purchase_order_status.dart';
import '../models/purchase_analytics_model.dart';
import '../models/purchase_order_detail_model.dart';
import '../models/purchase_order_summary_model.dart';
import '../models/supplier_balance_model.dart';
import '../models/supplier_invoice_model.dart';
import '../models/supplier_payment_model.dart';

/// See supabase/migrations/20260713000022_purchases_module.sql. Every
/// write/status-transition goes through an RPC; `getPaymentMethodIds()`
/// mirrors the Payments module's own small `payment_methods` lookup
/// rather than importing that module's datasource directly.
class PurchasesRemoteDataSource {
  PurchasesRemoteDataSource(this._client);
  final SupabaseClient _client;

  Map<PaymentMethod, String>? _methodIdCache;

  String _dateOnly(DateTime date) => date.toIso8601String().substring(0, 10);

  /// Mirrors PaymentRemoteDataSource's own generator exactly — the
  /// client never surfaces or manages this key itself, same
  /// convention as order payments.
  String _generateIdempotencyKey() {
    final userId = _client.auth.currentUser?.id ?? 'anon';
    return 'supplier-payment-$userId-${DateTime.now().microsecondsSinceEpoch}';
  }

  /// Only the fields `create_purchase_order()`/`update_purchase_order()`'s
  /// `jsonb_to_recordset()` column list expects — server-computed
  /// fields (item id, material/location display names, batch id,
  /// total) are never sent back up.
  Map<String, dynamic> _itemToRpcJson(PurchaseOrderItem item) => {
    'material_id': item.materialId,
    'quantity': item.quantity,
    'unit': item.unit,
    'unit_price_tiyn': item.unitPriceTiyn,
    'location_id': item.locationId,
  };

  Future<List<PurchaseOrderSummaryModel>> getPurchaseOrders({
    PurchaseOrderStatus? status,
    String? supplierPartnerId,
    String? search,
  }) async {
    final rows = await _client.rpc(
      'get_purchase_orders',
      params: {
        'p_status': status?.key,
        'p_supplier_partner_id': supplierPartnerId,
        'p_search': (search == null || search.trim().isEmpty)
            ? null
            : search.trim(),
      },
    );
    return (rows as List)
        .map(
          (row) =>
              PurchaseOrderSummaryModel.fromRow(row as Map<String, dynamic>),
        )
        .toList();
  }

  Future<PurchaseOrderDetailModel> getPurchaseOrderDetail(String id) async {
    final rows = await _client.rpc(
      'get_purchase_order_detail',
      params: {'p_id': id},
    );
    final list = rows as List;
    if (list.isEmpty) {
      throw const NotFoundException('Тапсырыс табылмады');
    }
    return PurchaseOrderDetailModel.fromRow(list.first as Map<String, dynamic>);
  }

  Future<String> createPurchaseOrder({
    required String orderNumber,
    required String supplierPartnerId,
    required List<PurchaseOrderItem> items,
    String? responsibleEmployeeId,
    DateTime? expectedDeliveryDate,
    required int deliveryCostTiyn,
    required int vatTiyn,
    required int discountTiyn,
    String? comment,
  }) async {
    try {
      final id = await _client.rpc(
        'create_purchase_order',
        params: {
          'p_order_number': orderNumber,
          'p_supplier_partner_id': supplierPartnerId,
          'p_items': items.map(_itemToRpcJson).toList(),
          'p_responsible_employee_id': responsibleEmployeeId,
          'p_expected_delivery_date': expectedDeliveryDate == null
              ? null
              : _dateOnly(expectedDeliveryDate),
          'p_delivery_cost_tiyn': deliveryCostTiyn,
          'p_vat_tiyn': vatTiyn,
          'p_discount_tiyn': discountTiyn,
          'p_comment': comment,
        },
      );
      return id as String;
    } on PostgrestException catch (e) {
      if (e.code == '42501') throw ServerException(e.message);
      rethrow;
    }
  }

  Future<void> updatePurchaseOrder({
    required String id,
    required String supplierPartnerId,
    required List<PurchaseOrderItem> items,
    String? responsibleEmployeeId,
    DateTime? expectedDeliveryDate,
    required int deliveryCostTiyn,
    required int vatTiyn,
    required int discountTiyn,
    String? comment,
  }) async {
    try {
      await _client.rpc(
        'update_purchase_order',
        params: {
          'p_id': id,
          'p_supplier_partner_id': supplierPartnerId,
          'p_items': items.map(_itemToRpcJson).toList(),
          'p_responsible_employee_id': responsibleEmployeeId,
          'p_expected_delivery_date': expectedDeliveryDate == null
              ? null
              : _dateOnly(expectedDeliveryDate),
          'p_delivery_cost_tiyn': deliveryCostTiyn,
          'p_vat_tiyn': vatTiyn,
          'p_discount_tiyn': discountTiyn,
          'p_comment': comment,
        },
      );
    } on PostgrestException catch (e) {
      if (e.code == '42501' || e.code == '23514') {
        throw ServerException(e.message);
      }
      rethrow;
    }
  }

  Future<void> approvePurchaseOrder(String id) async {
    try {
      await _client.rpc('approve_purchase_order', params: {'p_id': id});
    } on PostgrestException catch (e) {
      if (e.code == '42501' || e.code == '23514') {
        throw ServerException(e.message);
      }
      rethrow;
    }
  }

  Future<void> rejectPurchaseOrder(String id, {String? reason}) async {
    try {
      await _client.rpc(
        'reject_purchase_order',
        params: {'p_id': id, 'p_reason': reason},
      );
    } on PostgrestException catch (e) {
      if (e.code == '42501' || e.code == '23514') {
        throw ServerException(e.message);
      }
      rethrow;
    }
  }

  Future<void> markPurchaseOrderDelivered(String id) async {
    try {
      await _client.rpc('mark_purchase_order_delivered', params: {'p_id': id});
    } on PostgrestException catch (e) {
      if (e.code == '42501' || e.code == '23514') {
        throw ServerException(e.message);
      }
      rethrow;
    }
  }

  Future<void> cancelPurchaseOrder(String id, {String? reason}) async {
    try {
      await _client.rpc(
        'cancel_purchase_order',
        params: {'p_id': id, 'p_reason': reason},
      );
    } on PostgrestException catch (e) {
      if (e.code == '42501' || e.code == '23514') {
        throw ServerException(e.message);
      }
      rethrow;
    }
  }

  Future<String> receivePurchaseOrder(String id) async {
    try {
      final invoiceId = await _client.rpc(
        'receive_purchase_order',
        params: {'p_id': id},
      );
      return invoiceId as String;
    } on PostgrestException catch (e) {
      if (e.code == '42501' || e.code == '23514') {
        throw ServerException(e.message);
      }
      rethrow;
    }
  }

  Future<Map<String, num>> getPendingPurchaseQuantities() async {
    final rows = await _client.rpc('get_pending_purchase_quantities');
    final map = <String, num>{};
    for (final row in rows as List) {
      final r = row as Map<String, dynamic>;
      map[r['material_id'] as String] = (r['pending_quantity'] as num?) ?? 0;
    }
    return map;
  }

  Future<List<SupplierInvoiceModel>> getSupplierInvoices(
    String partnerId,
  ) async {
    final rows = await _client.rpc(
      'get_supplier_invoices',
      params: {'p_partner_id': partnerId},
    );
    return (rows as List)
        .map((row) => SupplierInvoiceModel.fromRow(row as Map<String, dynamic>))
        .toList();
  }

  Future<List<SupplierPaymentModel>> getSupplierPayments(
    String partnerId,
  ) async {
    final rows = await _client.rpc(
      'get_supplier_payments',
      params: {'p_partner_id': partnerId},
    );
    return (rows as List)
        .map((row) => SupplierPaymentModel.fromRow(row as Map<String, dynamic>))
        .toList();
  }

  Future<void> recordSupplierPayment({
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
      await _client.rpc(
        'record_supplier_payment',
        params: {
          'p_idempotency_key': _generateIdempotencyKey(),
          'p_partner_id': partnerId,
          'p_amount_tiyn': amountTiyn,
          'p_method_id': methodId,
          'p_supplier_invoice_id': supplierInvoiceId,
          'p_cashbox_id': cashboxId,
          'p_bank_account_id': bankAccountId,
          'p_paid_at': paidAt == null ? null : _dateOnly(paidAt),
          'p_comment': comment,
        },
      );
    } on PostgrestException catch (e) {
      if (e.code == '42501' || e.code == '23514') {
        throw ServerException(e.message);
      }
      rethrow;
    }
  }

  Future<void> reverseSupplierPayment(String paymentId, String reason) async {
    try {
      await _client.rpc(
        'reverse_supplier_payment',
        params: {'p_payment_id': paymentId, 'p_reason': reason},
      );
    } on PostgrestException catch (e) {
      if (e.code == '42501' || e.code == 'P0002') {
        throw ServerException(e.message);
      }
      rethrow;
    }
  }

  Future<PurchaseAnalyticsModel> getPurchaseAnalytics() async {
    final rows = await _client.rpc('get_purchase_analytics');
    final list = rows as List;
    if (list.isEmpty) {
      return const PurchaseAnalyticsModel(
        monthlyPurchasesTiyn: 0,
        totalDebtTiyn: 0,
        totalAdvanceTiyn: 0,
        avgUnitPriceTiyn: 0,
        topMaterials: [],
        supplierRatings: [],
      );
    }
    return PurchaseAnalyticsModel.fromRow(list.first as Map<String, dynamic>);
  }

  /// Mirrors PaymentRemoteDataSource.getPaymentMethodIds() — same
  /// table, same 5 keys, cached locally rather than imported across
  /// features.
  Future<Map<PaymentMethod, String>> getPaymentMethodIds() async {
    final cached = _methodIdCache;
    if (cached != null) return cached;

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
    _methodIdCache = map;
    return map;
  }

  /// Requirement: "SupplierBalance" — reuses the Partners module's own
  /// `get_partners(p_id: ...)` RPC (see
  /// supabase/migrations/20260713000018_partners_module.sql) instead of
  /// a new Purchases RPC, since `partners.balance_tiyn` is already the
  /// authoritative ledger this module's own writes maintain.
  Future<SupplierBalanceModel> getSupplierBalance(String partnerId) async {
    final rows = await _client.rpc('get_partners', params: {'p_id': partnerId});
    final list = rows as List;
    if (list.isEmpty) {
      throw const NotFoundException('Серіктес табылмады');
    }
    return SupplierBalanceModel.fromRow(list.first as Map<String, dynamic>);
  }
}
