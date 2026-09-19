import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../../../core/error/failures.dart';
import '../../domain/entities/company_invitation.dart';
import '../../domain/entities/company_join_request.dart';
import '../../domain/entities/company_settings.dart';
import '../../domain/entities/company_subscription_info.dart';
import '../../domain/entities/pending_company_request.dart';
import '../../domain/entities/subscription_plan.dart';
import '../../domain/repositories/company_repository.dart';
import '../../domain/value_objects/company_role.dart';
import '../datasources/company_remote_datasource.dart';

class CompanyRepositoryImpl implements CompanyRepository {
  CompanyRepositoryImpl(this._remote);
  final CompanyRemoteDataSource _remote;

  @override
  Future<Either<Failure, String>> createCompanyAndOwner({
    required String name,
    String? phone,
    String? email,
    String? city,
    String? address,
    String? iinBin,
  }) async {
    try {
      final id = await _remote.createCompanyAndOwner(
        name: name,
        phone: phone,
        email: email,
        city: city,
        address: address,
        iinBin: iinBin,
      );
      return right(id);
    } on PostgrestException catch (e) {
      return left(_mapPostgrestError(e));
    } catch (e) {
      return left(mapUnexpectedError(e));
    }
  }

  @override
  Future<Either<Failure, String>> requestToJoinCompany({
    required String companyCode,
    required CompanyRole requestedRole,
    String? message,
  }) async {
    try {
      final id = await _remote.requestToJoinCompany(
        companyCode: companyCode,
        requestedRole: requestedRole,
        message: message,
      );
      return right(id);
    } on PostgrestException catch (e) {
      return left(_mapPostgrestError(e));
    } catch (e) {
      return left(mapUnexpectedError(e));
    }
  }

  @override
  Future<Either<Failure, Unit>> withdrawCompanyJoinRequest(
    String requestId,
  ) async {
    try {
      await _remote.withdrawCompanyJoinRequest(requestId);
      return right(unit);
    } on PostgrestException catch (e) {
      return left(_mapPostgrestError(e));
    } catch (e) {
      return left(mapUnexpectedError(e));
    }
  }

  @override
  Future<Either<Failure, List<CompanyJoinRequest>>> getMyJoinRequests() async {
    try {
      return right(await _remote.getMyJoinRequests());
    } on PostgrestException catch (e) {
      return left(_mapPostgrestError(e));
    } catch (e) {
      return left(mapUnexpectedError(e));
    }
  }

  @override
  Future<Either<Failure, List<PendingCompanyRequest>>>
  getPendingCompanyRequests() async {
    try {
      return right(await _remote.getPendingCompanyRequests());
    } on PostgrestException catch (e) {
      return left(_mapPostgrestError(e));
    } catch (e) {
      return left(mapUnexpectedError(e));
    }
  }

  @override
  Future<Either<Failure, Unit>> approveCompanyJoinRequest(
    String requestId, {
    CompanyRole? overrideRole,
  }) async {
    try {
      await _remote.approveCompanyJoinRequest(
        requestId,
        overrideRole: overrideRole,
      );
      return right(unit);
    } on PostgrestException catch (e) {
      return left(_mapPostgrestError(e));
    } catch (e) {
      return left(mapUnexpectedError(e));
    }
  }

  @override
  Future<Either<Failure, Unit>> rejectCompanyJoinRequest(
    String requestId, {
    String? reason,
  }) async {
    try {
      await _remote.rejectCompanyJoinRequest(requestId, reason: reason);
      return right(unit);
    } on PostgrestException catch (e) {
      return left(_mapPostgrestError(e));
    } catch (e) {
      return left(mapUnexpectedError(e));
    }
  }

  @override
  Future<Either<Failure, CompanyInvitation>> createCompanyInvitation({
    required CompanyRole role,
    int maxUses = 1,
    int expiresInHours = 168,
  }) async {
    try {
      final invitation = await _remote.createCompanyInvitation(
        role: role,
        maxUses: maxUses,
        expiresInHours: expiresInHours,
      );
      return right(invitation);
    } on PostgrestException catch (e) {
      return left(_mapPostgrestError(e));
    } catch (e) {
      return left(mapUnexpectedError(e));
    }
  }

  @override
  Future<Either<Failure, String>> acceptCompanyInvitation({
    required String code,
    String? message,
  }) async {
    try {
      final companyId = await _remote.acceptCompanyInvitation(
        code: code,
        message: message,
      );
      return right(companyId);
    } on PostgrestException catch (e) {
      return left(_mapPostgrestError(e));
    } catch (e) {
      return left(mapUnexpectedError(e));
    }
  }

  @override
  Future<Either<Failure, CompanySettings>> getCompanySettings() async {
    try {
      return right(await _remote.getCompanySettings());
    } on PostgrestException catch (e) {
      return left(_mapPostgrestError(e));
    } catch (e) {
      return left(mapUnexpectedError(e));
    }
  }

  @override
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
  }) async {
    try {
      await _remote.updateCompanySettings(
        name: name,
        logo: logo,
        phone: phone,
        email: email,
        address: address,
        iinBin: iinBin,
        website: website,
        timezone: timezone,
        currency: currency,
        workingHours: workingHours,
        description: description,
      );
      return right(unit);
    } on PostgrestException catch (e) {
      return left(_mapPostgrestError(e));
    } catch (e) {
      return left(mapUnexpectedError(e));
    }
  }

  @override
  Future<Either<Failure, CompanySubscriptionInfo>> getSubscriptionInfo() async {
    try {
      return right(await _remote.getSubscriptionInfo());
    } on PostgrestException catch (e) {
      return left(_mapPostgrestError(e));
    } catch (e) {
      return left(mapUnexpectedError(e));
    }
  }

  @override
  Future<Either<Failure, List<SubscriptionPlan>>> getSubscriptionPlans() async {
    try {
      return right(await _remote.getSubscriptionPlans());
    } on PostgrestException catch (e) {
      return left(_mapPostgrestError(e));
    } catch (e) {
      return left(mapUnexpectedError(e));
    }
  }

  Failure _mapPostgrestError(PostgrestException e) {
    if (e.code == '42501') return PermissionFailure(e.message);
    if (e.code == 'P0002' || e.code == 'PGRST116') {
      return NotFoundFailure(e.message);
    }
    if (e.code == '23514') return ValidationFailure(e.message);
    return ServerFailure(e.message);
  }
}
