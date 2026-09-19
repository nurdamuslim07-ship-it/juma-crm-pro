import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/partner.dart';
import '../entities/partner_document.dart';
import '../value_objects/partner_category.dart';

abstract class PartnerRepository {
  /// Routed entirely through `get_partners()` — see that RPC's doc
  /// comment in the migration for exactly which columns come back
  /// null (and which tier flags come back false) depending on the
  /// caller's permissions. [includeDeleted] is a director-only "trash"
  /// toggle; the server silently ignores it for anyone else.
  Future<Either<Failure, List<Partner>>> getPartners({
    String? searchQuery,
    PartnerCategory? categoryFilter,
    bool? activeFilter,
    bool includeDeleted = false,
    int limit = 50,
    int offset = 0,
  });

  Future<Either<Failure, Partner>> getPartner(String id);

  /// director/manager/purchaser (`partners.write`) — see `create_partner()`.
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
  });

  /// director/manager/purchaser (`partners.write`) — non-financial
  /// fields only, see `update_partner()`.
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
  });

  /// Director-only — routed through `update_partner_financials()`.
  Future<Either<Failure, Unit>> updatePartnerFinancials({
    required String id,
    String? bankDetails,
    required int balanceTiyn,
  });

  /// Requirement #5 — director-only, routed through `soft_delete_partner()`.
  Future<Either<Failure, Unit>> deletePartner(String id);

  /// Requirement #6 — director-only, routed through `restore_partner()`.
  Future<Either<Failure, Unit>> restorePartner(String id);

  /// director/manager/purchaser/accountant (`partners.read_extended` or
  /// `partners.read_financial`) — see `get_partner_documents()`.
  Future<Either<Failure, List<PartnerDocument>>> getPartnerDocuments(
    String partnerId,
  );

  /// Uploads the file to the private `partner-documents` bucket, then
  /// records the metadata row via `add_partner_document()`.
  Future<Either<Failure, PartnerDocument>> addPartnerDocument({
    required String partnerId,
    required List<int> bytes,
    required String fileName,
  });

  /// Removes both the metadata row and the underlying Storage object
  /// (see `delete_partner_document()`).
  Future<Either<Failure, Unit>> deletePartnerDocument(String documentId);

  Future<Either<Failure, String>> getDocumentSignedUrl(String storagePath);
}
