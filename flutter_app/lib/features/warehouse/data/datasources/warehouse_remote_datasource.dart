import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/exceptions.dart';
import '../../domain/entities/cart_item.dart';
import '../models/inventory_batch_model.dart';
import '../models/inventory_hold_model.dart';
import '../models/material_category_model.dart';
import '../models/material_stock_model.dart';
import '../models/warehouse_location_model.dart';
import '../models/warehouse_summary_model.dart';

/// See supabase/migrations/20260713000021_warehouse_module.sql.
/// Categories/locations are plain, unredacted table reads (their own
/// RLS is `read_all_active`, no `warehouse.read` gate — see that
/// migration's README section); everything else goes through an RPC.
class WarehouseRemoteDataSource {
  WarehouseRemoteDataSource(this._client);
  final SupabaseClient _client;

  Future<List<MaterialCategoryModel>> getCategories() async {
    final rows = await _client
        .from('material_categories')
        .select()
        .order('name_kk');
    return (rows as List)
        .map(
          (row) => MaterialCategoryModel.fromRow(row as Map<String, dynamic>),
        )
        .toList();
  }

  Future<List<WarehouseLocationModel>> getLocations() async {
    final rows = await _client
        .from('warehouse_locations')
        .select()
        .order('name');
    return (rows as List)
        .map(
          (row) => WarehouseLocationModel.fromRow(row as Map<String, dynamic>),
        )
        .toList();
  }

  Future<List<MaterialStockModel>> getMaterials({
    String? categoryId,
    String? search,
    bool lowStockOnly = false,
  }) async {
    final rows = await _client.rpc(
      'get_materials',
      params: {
        'p_category_id': categoryId,
        'p_search': (search == null || search.trim().isEmpty)
            ? null
            : search.trim(),
        'p_low_stock_only': lowStockOnly,
      },
    );
    return (rows as List)
        .map((row) => MaterialStockModel.fromRow(row as Map<String, dynamic>))
        .toList();
  }

  Future<WarehouseSummaryModel> getWarehouseSummary() async {
    final rows = await _client.rpc('get_warehouse_summary');
    final list = rows as List;
    if (list.isEmpty) {
      return const WarehouseSummaryModel(
        materialsCount: 0,
        lowStockCount: 0,
        totalInventoryValueTiyn: 0,
        categoryBreakdown: {},
      );
    }
    return WarehouseSummaryModel.fromRow(list.first as Map<String, dynamic>);
  }

  Future<String?> getMaterialIdByBarcode(String barcode) async {
    final id = await _client.rpc(
      'get_material_id_by_barcode',
      params: {'p_barcode': barcode},
    );
    return id as String?;
  }

  Future<List<InventoryBatchModel>> getBatches(String materialId) async {
    final rows = await _client
        .from('inventory_batches')
        .select('*, warehouse_locations(name)')
        .eq('material_id', materialId)
        .order('received_at', ascending: false);
    return (rows as List)
        .map((row) => InventoryBatchModel.fromRow(row as Map<String, dynamic>))
        .toList();
  }

  Future<List<InventoryHoldModel>> getActiveHolds(String materialId) async {
    final rows = await _client
        .from('inventory_holds')
        .select('*, warehouse_locations(name), profiles(full_name)')
        .eq('material_id', materialId)
        .filter('released_at', 'is', null)
        .order('created_at', ascending: false);
    return (rows as List)
        .map((row) => InventoryHoldModel.fromRow(row as Map<String, dynamic>))
        .toList();
  }

  Future<void> receiveMaterials({
    required String materialId,
    required String locationId,
    required num quantity,
    required int costPerUnitTiyn,
    String? batchNumber,
    String? supplierPartnerId,
  }) async {
    try {
      await _client.rpc(
        'receive_materials',
        params: {
          'p_material_id': materialId,
          'p_location_id': locationId,
          'p_quantity': quantity,
          'p_cost_per_unit_tiyn': costPerUnitTiyn,
          'p_batch_number': batchNumber,
          'p_supplier_partner_id': supplierPartnerId,
        },
      );
    } on PostgrestException catch (e) {
      if (e.code == '42501' || e.code == '23514') {
        throw ServerException(e.message);
      }
      rethrow;
    }
  }

  Future<void> issueMaterials({
    required List<CartItem> items,
    String? orderId,
  }) async {
    try {
      await _client.rpc(
        'issue_materials',
        params: {
          'p_items': items
              .map(
                (item) => {
                  'material_id': item.materialId,
                  'location_id': item.locationId,
                  'quantity': item.quantity,
                },
              )
              .toList(),
          'p_order_id': orderId,
        },
      );
    } on PostgrestException catch (e) {
      if (e.code == '42501' || e.code == '23514') {
        throw ServerException(e.message);
      }
      rethrow;
    }
  }

  Future<String> reserveMaterialForOrder({
    required String orderId,
    required String materialId,
    required num quantity,
    String? locationId,
  }) async {
    try {
      final id = await _client.rpc(
        'reserve_material_for_order',
        params: {
          'p_order_id': orderId,
          'p_material_id': materialId,
          'p_quantity': quantity,
          'p_location_id': locationId,
        },
      );
      return id as String;
    } on PostgrestException catch (e) {
      if (e.code == '42501' || e.code == '23514') {
        throw ServerException(e.message);
      }
      rethrow;
    }
  }

  Future<void> releaseOrderReservation(String reservationId) async {
    try {
      await _client.rpc(
        'release_order_reservation',
        params: {'p_reservation_id': reservationId},
      );
    } on PostgrestException catch (e) {
      if (e.code == '42501' || e.code == 'P0002') {
        throw ServerException(e.message);
      }
      rethrow;
    }
  }

  Future<String> createHold({
    required String materialId,
    required String locationId,
    required num quantity,
    String? reason,
  }) async {
    try {
      final id = await _client.rpc(
        'create_hold',
        params: {
          'p_material_id': materialId,
          'p_location_id': locationId,
          'p_quantity': quantity,
          'p_reason': reason,
        },
      );
      return id as String;
    } on PostgrestException catch (e) {
      if (e.code == '42501' || e.code == '23514') {
        throw ServerException(e.message);
      }
      rethrow;
    }
  }

  Future<void> releaseHold(String holdId) async {
    try {
      await _client.rpc('release_hold', params: {'p_hold_id': holdId});
    } on PostgrestException catch (e) {
      if (e.code == '42501' || e.code == 'P0002') {
        throw ServerException(e.message);
      }
      rethrow;
    }
  }
}
