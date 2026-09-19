import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/company_invitation.dart';
import '../entities/company_join_request.dart';
import '../entities/company_settings.dart';
import '../entities/company_subscription_info.dart';
import '../entities/pending_company_request.dart';
import '../entities/subscription_plan.dart';
import '../value_objects/company_role.dart';

/// Domain-layer contract for the 9 company-registration RPCs — see
/// supabase/migrations/20260713000036_company_registration_module.sql.
/// Every method deliberately has NO `companyId` parameter anywhere:
/// the caller's company is always derived server-side from
/// `auth_company_id()` (the same "never trust a client-supplied
/// company_id" rule the whole multi-tenant conversion enforces).
abstract class CompanyRepository {
  /// Creates a new company and activates the caller as its `owner`.
  /// Requires the caller to currently have no company.
  Future<Either<Failure, String>> createCompanyAndOwner({
    required String name,
    String? phone,
    String? email,
    String? city,
    String? address,
    String? iinBin,
  });

  /// Looks up a company by its short lookup `code` (not an invite
  /// code — see [acceptCompanyInvitation]) and files a pending join
  /// request under the requested role.
  Future<Either<Failure, String>> requestToJoinCompany({
    required String companyCode,
    required CompanyRole requestedRole,
    String? message,
  });

  /// Cancels the caller's own pending request, resetting them back to
  /// the same no-company state a fresh signup starts in.
  Future<Either<Failure, Unit>> withdrawCompanyJoinRequest(String requestId);

  /// The caller's own join-request history.
  Future<Either<Failure, List<CompanyJoinRequest>>> getMyJoinRequests();

  /// The caller's own company's incoming pending requests —
  /// director/owner only, never another company's.
  Future<Either<Failure, List<PendingCompanyRequest>>>
  getPendingCompanyRequests();

  /// Director/owner only. `overrideRole` lets the director grant a
  /// different role than the one requested.
  Future<Either<Failure, Unit>> approveCompanyJoinRequest(
    String requestId, {
    CompanyRole? overrideRole,
  });

  Future<Either<Failure, Unit>> rejectCompanyJoinRequest(
    String requestId, {
    String? reason,
  });

  /// Director/owner only. Single-use by default, expires after
  /// [expiresInHours] (default 7 days server-side).
  Future<Either<Failure, CompanyInvitation>> createCompanyInvitation({
    required CompanyRole role,
    int maxUses = 1,
    int expiresInHours = 168,
  });

  /// Redeems an invite code — activates membership immediately, no
  /// separate approval step (the invite itself is the approval).
  Future<Either<Failure, String>> acceptCompanyInvitation({
    required String code,
    String? message,
  });

  /// The caller's own company's editable settings — see
  /// supabase/migrations/20260713000038_company_settings_subscription.sql.
  Future<Either<Failure, CompanySettings>> getCompanySettings();

  /// Director/owner only.
  Future<Either<Failure, Unit>> updateCompanySettings({
    required String name,
    String? logo,
    String? phone,
    String? email,
    String? address,
    String? iinBin,
    String? website,
    String? timezone,
    String? currency,
    String? workingHours,
    String? description,
  });

  /// The caller's own company's plan/limits/usage — any active member,
  /// not director-only (see `get_company_subscription_info()`'s own
  /// header comment).
  Future<Either<Failure, CompanySubscriptionInfo>> getSubscriptionInfo();

  /// The public plan catalog, price-ordered.
  Future<Either<Failure, List<SubscriptionPlan>>> getSubscriptionPlans();
}
