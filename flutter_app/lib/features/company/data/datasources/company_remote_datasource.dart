import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/value_objects/company_role.dart';
import '../models/company_invitation_model.dart';
import '../models/company_join_request_model.dart';
import '../models/company_settings_model.dart';
import '../models/company_subscription_info_model.dart';
import '../models/pending_company_request_model.dart';
import '../models/subscription_plan_model.dart';

/// Talks to the 9 company-registration RPCs — see
/// supabase/migrations/20260713000036_company_registration_module.sql.
/// `company_join_requests`/`company_invitations` have all direct table
/// grants revoked (same pattern as `employees`/`partners` — see that
/// migration's header comment), so this is the only access path, same
/// as EmployeeRemoteDataSource for its own tables. `company_id` is
/// never one of the params sent below — every RPC derives it
/// server-side from `auth_company_id()`.
class CompanyRemoteDataSource {
  CompanyRemoteDataSource(this._client);
  final SupabaseClient _client;

  Future<String> createCompanyAndOwner({
    required String name,
    String? phone,
    String? email,
    String? city,
    String? address,
    String? iinBin,
  }) async {
    final id = await _client.rpc(
      'create_company_and_owner',
      params: {
        'p_name': name,
        'p_phone': phone,
        'p_email': email,
        'p_city': city,
        'p_address': address,
        'p_iin_bin': iinBin,
      },
    );
    return id as String;
  }

  Future<String> requestToJoinCompany({
    required String companyCode,
    required CompanyRole requestedRole,
    String? message,
  }) async {
    final id = await _client.rpc(
      'request_to_join_company',
      params: {
        'p_company_code': companyCode,
        'p_requested_role': requestedRole.dbKey,
        'p_message': message,
      },
    );
    return id as String;
  }

  Future<void> withdrawCompanyJoinRequest(String requestId) async {
    await _client.rpc(
      'withdraw_company_join_request',
      params: {'p_request_id': requestId},
    );
  }

  Future<List<CompanyJoinRequestModel>> getMyJoinRequests() async {
    final rows = await _client.rpc('get_my_join_requests');
    return (rows as List)
        .map(
          (row) => CompanyJoinRequestModel.fromRow(row as Map<String, dynamic>),
        )
        .toList();
  }

  Future<List<PendingCompanyRequestModel>> getPendingCompanyRequests() async {
    final rows = await _client.rpc('get_pending_company_requests');
    return (rows as List)
        .map(
          (row) =>
              PendingCompanyRequestModel.fromRow(row as Map<String, dynamic>),
        )
        .toList();
  }

  Future<void> approveCompanyJoinRequest(
    String requestId, {
    CompanyRole? overrideRole,
  }) async {
    await _client.rpc(
      'approve_company_join_request',
      params: {
        'p_request_id': requestId,
        'p_override_role_key': overrideRole?.dbKey,
      },
    );
  }

  Future<void> rejectCompanyJoinRequest(
    String requestId, {
    String? reason,
  }) async {
    await _client.rpc(
      'reject_company_join_request',
      params: {'p_request_id': requestId, 'p_reason': reason},
    );
  }

  Future<CompanyInvitationModel> createCompanyInvitation({
    required CompanyRole role,
    int maxUses = 1,
    int expiresInHours = 168,
  }) async {
    final rows = await _client.rpc(
      'create_company_invitation',
      params: {
        'p_role_key': role.dbKey,
        'p_max_uses': maxUses,
        'p_expires_in_hours': expiresInHours,
      },
    );
    final list = rows as List;
    return CompanyInvitationModel.fromRow(list.first as Map<String, dynamic>);
  }

  Future<String> acceptCompanyInvitation({
    required String code,
    String? message,
  }) async {
    final id = await _client.rpc(
      'accept_company_invitation',
      params: {'p_code': code, 'p_message': message},
    );
    return id as String;
  }

  /// Direct table read — `companies` has no write policy at all (see
  /// supabase/migrations/20260713000038's own header comment), so RLS
  /// alone (`companies_select_own`) already scopes this to exactly the
  /// caller's own row; no filter is needed since only one row is ever
  /// visible.
  Future<CompanySettingsModel> getCompanySettings() async {
    final row = await _client.from('companies').select().single();
    return CompanySettingsModel.fromRow(row);
  }

  Future<void> updateCompanySettings({
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
  }) async {
    await _client.rpc(
      'update_company_settings',
      params: {
        'p_name': name,
        'p_logo': logo,
        'p_phone': phone,
        'p_email': email,
        'p_address': address,
        'p_iin_bin': iinBin,
        'p_website': website,
        'p_timezone': timezone,
        'p_currency': currency,
        'p_working_hours': workingHours,
        'p_description': description,
      },
    );
  }

  Future<CompanySubscriptionInfoModel> getSubscriptionInfo() async {
    final rows = await _client.rpc('get_company_subscription_info');
    final list = rows as List;
    return CompanySubscriptionInfoModel.fromRow(
      list.first as Map<String, dynamic>,
    );
  }

  Future<List<SubscriptionPlanModel>> getSubscriptionPlans() async {
    final rows = await _client.rpc('get_subscription_plans');
    return (rows as List)
        .map(
          (row) => SubscriptionPlanModel.fromRow(row as Map<String, dynamic>),
        )
        .toList();
  }
}
