import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show PostgrestException, StorageException;

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/partner.dart';
import '../../domain/entities/partner_document.dart';
import '../../domain/repositories/partner_repository.dart';
import '../../domain/value_objects/partner_category.dart';
import '../datasources/partner_remote_datasource.dart';

class PartnerRepositoryImpl implements PartnerRepository {
  PartnerRepositoryImpl(this._remote);
  final PartnerRemoteDataSource _remote;

  @override
  Future<Either<Failure, List<Partner>>> getPartners({
    String? searchQuery,
    PartnerCategory? categoryFilter,
    bool? activeFilter,
    bool includeDeleted = false,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final partners = await _remote.getPartners(
        searchQuery: searchQuery,
        categoryFilter: categoryFilter,
        activeFilter: activeFilter,
        includeDeleted: includeDeleted,
        limit: limit,
        offset: offset,
      );
      return right(partners);
    } on PostgrestException catch (e) {
      return left(_mapPostgrestError(e));
    } catch (e) {
      return left(mapUnexpectedError(e));
    }
  }

  @override
  Future<Either<Failure, Partner>> getPartner(String id) async {
    try {
      final partner = await _remote.getPartner(id);
      return right(partner);
    } on NotFoundException catch (e) {
      return left(NotFoundFailure(e.message ?? 'Серіктес табылмады'));
    } on PostgrestException catch (e) {
      return left(_mapPostgrestError(e));
    } catch (e) {
      return left(mapUnexpectedError(e));
    }
  }

  @override
  Future<Either<Failure, String>> createPartner({
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
      final id = await _remote.createPartner(
        displayName: displayName,
        category: category,
        companyName: companyName,
        phone: phone,
        phoneSecondary: phoneSecondary,
        whatsappPhone: whatsappPhone,
        address: address,
        city: city,
        contactPerson: contactPerson,
        taxId: taxId,
        serviceDescription: serviceDescription,
        priceNote: priceNote,
        trustRating: trustRating,
        notes: notes,
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
  Future<Either<Failure, Unit>> updatePartner({
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
      await _remote.updatePartner(
        id: id,
        displayName: displayName,
        category: category,
        companyName: companyName,
        phone: phone,
        phoneSecondary: phoneSecondary,
        whatsappPhone: whatsappPhone,
        address: address,
        city: city,
        contactPerson: contactPerson,
        taxId: taxId,
        serviceDescription: serviceDescription,
        priceNote: priceNote,
        trustRating: trustRating,
        notes: notes,
        isActive: isActive,
      );
      return right(unit);
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
  Future<Either<Failure, Unit>> updatePartnerFinancials({
    required String id,
    String? bankDetails,
    required int balanceTiyn,
  }) async {
    try {
      await _remote.updatePartnerFinancials(
        id: id,
        bankDetails: bankDetails,
        balanceTiyn: balanceTiyn,
      );
      return right(unit);
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
  Future<Either<Failure, Unit>> deletePartner(String id) async {
    try {
      await _remote.deletePartner(id);
      return right(unit);
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
  Future<Either<Failure, Unit>> restorePartner(String id) async {
    try {
      await _remote.restorePartner(id);
      return right(unit);
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
  Future<Either<Failure, List<PartnerDocument>>> getPartnerDocuments(
    String partnerId,
  ) async {
    try {
      final documents = await _remote.getPartnerDocuments(partnerId);
      return right(documents);
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
  Future<Either<Failure, PartnerDocument>> addPartnerDocument({
    required String partnerId,
    required List<int> bytes,
    required String fileName,
  }) async {
    try {
      final document = await _remote.addPartnerDocument(
        partnerId: partnerId,
        bytes: bytes,
        fileName: fileName,
      );
      return right(document);
    } on ServerException catch (e) {
      return left(
        e.message == null
            ? const PermissionFailure()
            : PermissionFailure(e.message!),
      );
    } on StorageException catch (e) {
      return left(ServerFailure(e.message));
    } on PostgrestException catch (e) {
      return left(_mapPostgrestError(e));
    } catch (e) {
      return left(mapUnexpectedError(e));
    }
  }

  @override
  Future<Either<Failure, Unit>> deletePartnerDocument(String documentId) async {
    try {
      await _remote.deletePartnerDocument(documentId);
      return right(unit);
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
  Future<Either<Failure, String>> getDocumentSignedUrl(
    String storagePath,
  ) async {
    try {
      final url = await _remote.getDocumentSignedUrl(storagePath);
      return right(url);
    } on StorageException catch (e) {
      return left(ServerFailure(e.message));
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
