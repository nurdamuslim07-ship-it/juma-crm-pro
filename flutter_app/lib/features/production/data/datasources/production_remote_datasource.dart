import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/exceptions.dart';
import '../models/production_detail_model.dart';
import '../models/production_master_model.dart';
import '../models/production_photo_model.dart';
import '../models/production_queue_item_model.dart';
import '../models/production_stage_model.dart';

/// See supabase/migrations/20260713000020_production_module.sql. Queue/
/// detail/move/assign/time-log actions all go through RPCs; photos go
/// straight through the `order_photos` table + `order-photos` Storage
/// bucket, since that table's own RLS already permits it for
/// `production.write` holders (no RPC wrapper needed there, same
/// reasoning as avatars/receipts in Employees/Payments).
class ProductionRemoteDataSource {
  ProductionRemoteDataSource(this._client);
  final SupabaseClient _client;

  Future<List<ProductionStageModel>> getStages() async {
    final rows = await _client
        .from('production_stages')
        .select()
        .order('sort_order');
    return (rows as List)
        .map((row) => ProductionStageModel.fromRow(row as Map<String, dynamic>))
        .toList();
  }

  Future<List<ProductionMasterModel>> getMasters() async {
    final rows = await _client.rpc('get_masters');
    return (rows as List)
        .map(
          (row) => ProductionMasterModel.fromRow(row as Map<String, dynamic>),
        )
        .toList();
  }

  Future<List<ProductionQueueItemModel>> getQueue({
    String? stageId,
    String? masterId,
    String? search,
  }) async {
    final rows = await _client.rpc(
      'get_production_queue',
      params: {
        'p_stage_id': stageId,
        'p_master_id': masterId,
        'p_search': (search == null || search.trim().isEmpty)
            ? null
            : search.trim(),
      },
    );
    return (rows as List)
        .map(
          (row) =>
              ProductionQueueItemModel.fromRow(row as Map<String, dynamic>),
        )
        .toList();
  }

  Future<ProductionDetailModel> getOrderDetail(String orderId) async {
    final rows = await _client.rpc(
      'get_order_production_detail',
      params: {'p_order_id': orderId},
    );
    final list = rows as List;
    if (list.isEmpty) {
      throw const NotFoundException('Тапсырыс табылмады');
    }
    return ProductionDetailModel.fromRow(list.first as Map<String, dynamic>);
  }

  Future<void> moveOrderToStage({
    required String orderId,
    required String stageId,
    String? comment,
  }) async {
    try {
      await _client.rpc(
        'move_order_to_stage',
        params: {
          'p_order_id': orderId,
          'p_stage_id': stageId,
          'p_comment': comment,
        },
      );
    } on PostgrestException catch (e) {
      if (e.code == '42501') throw ServerException(e.message);
      rethrow;
    }
  }

  Future<void> setOrderMaster({
    required String orderId,
    required String masterId,
  }) async {
    try {
      await _client.rpc(
        'set_order_master',
        params: {'p_order_id': orderId, 'p_master_id': masterId},
      );
    } on PostgrestException catch (e) {
      if (e.code == '42501') throw ServerException(e.message);
      rethrow;
    }
  }

  Future<String> startTimeLog({
    required String orderId,
    String? stageId,
  }) async {
    try {
      final id = await _client.rpc(
        'start_time_log',
        params: {'p_order_id': orderId, 'p_stage_id': stageId},
      );
      return id as String;
    } on PostgrestException catch (e) {
      if (e.code == '42501' || e.code == '23514') {
        throw ServerException(e.message);
      }
      rethrow;
    }
  }

  Future<void> stopTimeLog(String logId) async {
    try {
      await _client.rpc('stop_time_log', params: {'p_log_id': logId});
    } on PostgrestException catch (e) {
      if (e.code == '42501' || e.code == 'P0002') {
        throw ServerException(e.message);
      }
      rethrow;
    }
  }

  /// `companyId` is required (never optional/hardcoded) — the caller
  /// resolves it from the authenticated user's own active company
  /// (see ProductionPhotoGallery). `order_photos.company_id` is
  /// `not null` with no default, so an omitted value fails the insert
  /// outright.
  Future<ProductionPhotoModel> addPhoto({
    required String orderId,
    required List<int> bytes,
    required String fileName,
    required String companyId,
  }) async {
    final path = '$orderId/${DateTime.now().millisecondsSinceEpoch}-$fileName';
    await _client.storage
        .from('order-photos')
        .uploadBinary(path, Uint8List.fromList(bytes));

    try {
      final row = await _client
          .from('order_photos')
          .insert({
            'order_id': orderId,
            'storage_path': path,
            'kind': 'production',
            'uploaded_by': _client.auth.currentUser?.id,
            'company_id': companyId,
          })
          .select()
          .single();
      return ProductionPhotoModel.fromRow(row);
    } on PostgrestException catch (e) {
      if (e.code == '42501') throw ServerException(e.message);
      rethrow;
    }
  }

  Future<void> deletePhoto(String photoId) async {
    try {
      final row = await _client
          .from('order_photos')
          .select('storage_path')
          .eq('id', photoId)
          .single();
      await _client.from('order_photos').delete().eq('id', photoId);
      final path = row['storage_path'] as String?;
      if (path != null) {
        await _client.storage.from('order-photos').remove([path]);
      }
    } on PostgrestException catch (e) {
      if (e.code == '42501') throw ServerException(e.message);
      rethrow;
    }
  }

  Future<String> getPhotoSignedUrl(String storagePath) {
    return _client.storage
        .from('order-photos')
        .createSignedUrl(storagePath, 60 * 10);
  }
}
