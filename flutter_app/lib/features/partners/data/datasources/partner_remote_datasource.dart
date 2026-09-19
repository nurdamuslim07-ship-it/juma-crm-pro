import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/exceptions.dart';
import '../../domain/value_objects/partner_category.dart';
import '../models/partner_document_model.dart';
import '../models/partner_model.dart';

/// See supabase/migrations/20260713000018_partners_module.sql. Every
/// read/write here goes through an RPC or Storage — this class never
/// issues a raw `.from('partners')`/`.from('partner_documents')` query,
/// because the base tables have no grants for `authenticated` at all
/// (see that migration's header comment).
class PartnerRemoteDataSource {
  PartnerRemoteDataSource(this._client);
  final SupabaseClient _client;

  Future<List<PartnerModel>> getPartners({
    String? searchQuery,
    PartnerCategory? categoryFilter,
    bool? activeFilter,
    bool includeDeleted = false,
    int limit = 50,
    int offset = 0,
  }) async {
    final rows = await _client.rpc(
      'get_partners',
      params: {
        'p_search': (searchQuery == null || searchQuery.trim().isEmpty)
            ? null
            : searchQuery.trim(),
        'p_category': categoryFilter?.dbKey,
        'p_active_filter': activeFilter,
        'p_include_deleted': includeDeleted,
        'p_limit': limit,
        'p_offset': offset,
      },
    );
    return (rows as List)
        .map((row) => PartnerModel.fromRow(row as Map<String, dynamic>))
        .toList();
  }

  Future<PartnerModel> getPartner(String id) async {
    final rows = await _client.rpc(
      'get_partners',
      params: {'p_id': id, 'p_include_deleted': true},
    );
    final list = rows as List;
    if (list.isEmpty) {
      throw const NotFoundException('Серіктес табылмады');
    }
    return PartnerModel.fromRow(list.first as Map<String, dynamic>);
  }

  Future<String> createPartner({
    required String displayName,
    required PartnerCategory category,
    String? companyName,
    String? phone,
    String? phoneSecondary,
    String? whatsappPhone,
    String? address,
    String? city,
    String? contactPerson,
    String? taxId,
    String? serviceDescription,
    String? priceNote,
    int? trustRating,
    String? notes,
  }) async {
    try {
      final id = await _client.rpc(
        'create_partner',
        params: {
          'p_display_name': displayName,
          'p_category': category.dbKey,
          'p_company_name': companyName,
          'p_phone': phone,
          'p_phone_secondary': phoneSecondary,
          'p_whatsapp_phone': whatsappPhone,
          'p_address': address,
          'p_city': city,
          'p_contact_person': contactPerson,
          'p_tax_id': taxId,
          'p_service_description': serviceDescription,
          'p_price_note': priceNote,
          'p_trust_rating': trustRating,
          'p_notes': notes,
        },
      );
      return id as String;
    } on PostgrestException catch (e) {
      if (e.code == '42501') throw ServerException(e.message);
      rethrow;
    }
  }

  Future<void> updatePartner({
    required String id,
    required String displayName,
    required PartnerCategory category,
    String? companyName,
    String? phone,
    String? phoneSecondary,
    String? whatsappPhone,
    String? address,
    String? city,
    String? contactPerson,
    String? taxId,
    String? serviceDescription,
    String? priceNote,
    int? trustRating,
    String? notes,
    required bool isActive,
  }) async {
    try {
      await _client.rpc(
        'update_partner',
        params: {
          'p_id': id,
          'p_display_name': displayName,
          'p_category': category.dbKey,
          'p_company_name': companyName,
          'p_phone': phone,
          'p_phone_secondary': phoneSecondary,
          'p_whatsapp_phone': whatsappPhone,
          'p_address': address,
          'p_city': city,
          'p_contact_person': contactPerson,
          'p_tax_id': taxId,
          'p_service_description': serviceDescription,
          'p_price_note': priceNote,
          'p_trust_rating': trustRating,
          'p_notes': notes,
          'p_is_active': isActive,
        },
      );
    } on PostgrestException catch (e) {
      if (e.code == '42501') throw ServerException(e.message);
      rethrow;
    }
  }

  Future<void> updatePartnerFinancials({
    required String id,
    String? bankDetails,
    required int balanceTiyn,
  }) async {
    try {
      await _client.rpc(
        'update_partner_financials',
        params: {
          'p_id': id,
          'p_bank_details': bankDetails,
          'p_balance_tiyn': balanceTiyn,
        },
      );
    } on PostgrestException catch (e) {
      if (e.code == '42501') throw ServerException(e.message);
      rethrow;
    }
  }

  Future<void> deletePartner(String id) async {
    try {
      await _client.rpc('soft_delete_partner', params: {'p_id': id});
    } on PostgrestException catch (e) {
      if (e.code == '42501') throw ServerException(e.message);
      rethrow;
    }
  }

  Future<void> restorePartner(String id) async {
    try {
      await _client.rpc('restore_partner', params: {'p_id': id});
    } on PostgrestException catch (e) {
      if (e.code == '42501') throw ServerException(e.message);
      rethrow;
    }
  }

  Future<List<PartnerDocumentModel>> getPartnerDocuments(
    String partnerId,
  ) async {
    try {
      final rows = await _client.rpc(
        'get_partner_documents',
        params: {'p_partner_id': partnerId},
      );
      return (rows as List)
          .map(
            (row) => PartnerDocumentModel.fromRow(row as Map<String, dynamic>),
          )
          .toList();
    } on PostgrestException catch (e) {
      if (e.code == '42501') throw ServerException(e.message);
      rethrow;
    }
  }

  Future<PartnerDocumentModel> addPartnerDocument({
    required String partnerId,
    required List<int> bytes,
    required String fileName,
  }) async {
    final path =
        '$partnerId/${DateTime.now().millisecondsSinceEpoch}-$fileName';
    await _client.storage
        .from('partner-documents')
        .uploadBinary(path, Uint8List.fromList(bytes));

    try {
      final id = await _client.rpc(
        'add_partner_document',
        params: {
          'p_partner_id': partnerId,
          'p_storage_path': path,
          'p_file_name': fileName,
        },
      );
      return PartnerDocumentModel(
        id: id as String,
        partnerId: partnerId,
        storagePath: path,
        fileName: fileName,
        uploadedBy: _client.auth.currentUser?.id,
        createdAt: DateTime.now(),
      );
    } on PostgrestException catch (e) {
      if (e.code == '42501') throw ServerException(e.message);
      rethrow;
    }
  }

  Future<void> deletePartnerDocument(String documentId) async {
    try {
      await _client.rpc(
        'delete_partner_document',
        params: {'p_id': documentId},
      );
    } on PostgrestException catch (e) {
      if (e.code == '42501') throw ServerException(e.message);
      rethrow;
    }
  }

  Future<String> getDocumentSignedUrl(String storagePath) {
    return _client.storage
        .from('partner-documents')
        .createSignedUrl(storagePath, 60 * 10);
  }
}
