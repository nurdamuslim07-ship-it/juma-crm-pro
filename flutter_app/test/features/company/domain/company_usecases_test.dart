import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:juma_ui_crm/core/error/failures.dart';
import 'package:juma_ui_crm/features/company/domain/entities/company_invitation.dart';
import 'package:juma_ui_crm/features/company/domain/entities/company_join_request.dart';
import 'package:juma_ui_crm/features/company/domain/entities/company_settings.dart';
import 'package:juma_ui_crm/features/company/domain/entities/company_subscription_info.dart';
import 'package:juma_ui_crm/features/company/domain/entities/pending_company_request.dart';
import 'package:juma_ui_crm/features/company/domain/entities/subscription_plan.dart';
import 'package:juma_ui_crm/features/company/domain/repositories/company_repository.dart';
import 'package:juma_ui_crm/features/company/domain/usecases/accept_company_invitation_usecase.dart';
import 'package:juma_ui_crm/features/company/domain/usecases/approve_company_join_request_usecase.dart';
import 'package:juma_ui_crm/features/company/domain/usecases/create_company_and_owner_usecase.dart';
import 'package:juma_ui_crm/features/company/domain/usecases/create_company_invitation_usecase.dart';
import 'package:juma_ui_crm/features/company/domain/usecases/get_company_settings_usecase.dart';
import 'package:juma_ui_crm/features/company/domain/usecases/get_pending_company_requests_usecase.dart';
import 'package:juma_ui_crm/features/company/domain/usecases/get_subscription_info_usecase.dart';
import 'package:juma_ui_crm/features/company/domain/usecases/get_subscription_plans_usecase.dart';
import 'package:juma_ui_crm/features/company/domain/usecases/reject_company_join_request_usecase.dart';
import 'package:juma_ui_crm/features/company/domain/usecases/request_to_join_company_usecase.dart';
import 'package:juma_ui_crm/features/company/domain/usecases/update_company_settings_usecase.dart';
import 'package:juma_ui_crm/features/company/domain/usecases/withdraw_company_join_request_usecase.dart';
import 'package:juma_ui_crm/features/company/domain/value_objects/company_role.dart';
import 'package:juma_ui_crm/features/company/domain/value_objects/join_request_status.dart';

/// Hand-written fake — no mocking framework exists anywhere in this
/// codebase (checked: zero datasource/repository tests precedent), so
/// usecase tests fake the DOMAIN-layer repository interface directly,
/// same spirit as every other Either-returning repository in this app.
class _FakeCompanyRepository implements CompanyRepository {
  Failure? failureToReturn;
  String? lastRequestedCompanyCode;
  CompanyRole? lastRequestedRole;
  String? lastApprovedRequestId;
  CompanyRole? lastOverrideRole;
  String? lastRejectedRequestId;
  String? lastRejectionReason;
  bool ownerCreated = false;
  bool invitationAccepted = false;

  @override
  Future<Either<Failure, String>> createCompanyAndOwner({
    required String name,
    String? phone,
    String? email,
    String? city,
    String? address,
    String? iinBin,
  }) async {
    if (failureToReturn != null) return left(failureToReturn!);
    ownerCreated = true;
    return right('company-1');
  }

  @override
  Future<Either<Failure, String>> requestToJoinCompany({
    required String companyCode,
    required CompanyRole requestedRole,
    String? message,
  }) async {
    lastRequestedCompanyCode = companyCode;
    lastRequestedRole = requestedRole;
    if (failureToReturn != null) return left(failureToReturn!);
    return right('request-1');
  }

  @override
  Future<Either<Failure, Unit>> withdrawCompanyJoinRequest(
    String requestId,
  ) async {
    if (failureToReturn != null) return left(failureToReturn!);
    return right(unit);
  }

  @override
  Future<Either<Failure, List<CompanyJoinRequest>>> getMyJoinRequests() async {
    if (failureToReturn != null) return left(failureToReturn!);
    return right([
      CompanyJoinRequest(
        id: 'request-1',
        companyId: 'company-1',
        companyName: 'Test Company',
        requestedRole: CompanyRole.assistant,
        status: JoinRequestStatus.pending,
        createdAt: DateTime(2026),
      ),
    ]);
  }

  @override
  Future<Either<Failure, List<PendingCompanyRequest>>>
  getPendingCompanyRequests() async {
    if (failureToReturn != null) return left(failureToReturn!);
    return right([
      PendingCompanyRequest(
        id: 'request-1',
        profileId: 'profile-1',
        fullName: 'Test User',
        requestedRole: CompanyRole.assistant,
        createdAt: DateTime(2026),
      ),
    ]);
  }

  @override
  Future<Either<Failure, Unit>> approveCompanyJoinRequest(
    String requestId, {
    CompanyRole? overrideRole,
  }) async {
    lastApprovedRequestId = requestId;
    lastOverrideRole = overrideRole;
    if (failureToReturn != null) return left(failureToReturn!);
    return right(unit);
  }

  @override
  Future<Either<Failure, Unit>> rejectCompanyJoinRequest(
    String requestId, {
    String? reason,
  }) async {
    lastRejectedRequestId = requestId;
    lastRejectionReason = reason;
    if (failureToReturn != null) return left(failureToReturn!);
    return right(unit);
  }

  @override
  Future<Either<Failure, CompanyInvitation>> createCompanyInvitation({
    required CompanyRole role,
    int maxUses = 1,
    int expiresInHours = 168,
  }) async {
    if (failureToReturn != null) return left(failureToReturn!);
    return right(
      CompanyInvitation(code: 'ABC12345', expiresAt: DateTime(2026, 2)),
    );
  }

  @override
  Future<Either<Failure, String>> acceptCompanyInvitation({
    required String code,
    String? message,
  }) async {
    if (failureToReturn != null) return left(failureToReturn!);
    invitationAccepted = true;
    return right('company-1');
  }

  @override
  Future<Either<Failure, CompanySettings>> getCompanySettings() async {
    if (failureToReturn != null) return left(failureToReturn!);
    return right(
      const CompanySettings(
        id: 'company-1',
        name: 'Test Company',
        timezone: 'Asia/Almaty',
        currency: 'KZT',
      ),
    );
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
    if (failureToReturn != null) return left(failureToReturn!);
    return right(unit);
  }

  @override
  Future<Either<Failure, CompanySubscriptionInfo>> getSubscriptionInfo() async {
    if (failureToReturn != null) return left(failureToReturn!);
    return right(
      CompanySubscriptionInfo(
        planKey: 'free',
        planNameKk: 'Тегін',
        status: 'active',
        startedAt: DateTime(2026),
        isTrial: false,
        companyIsActive: true,
        activeUsers: 1,
      ),
    );
  }

  @override
  Future<Either<Failure, List<SubscriptionPlan>>> getSubscriptionPlans() async {
    if (failureToReturn != null) return left(failureToReturn!);
    return right(const [
      SubscriptionPlan(
        key: 'free',
        nameKk: 'Тегін',
        priceTiyn: 0,
        features: {},
      ),
    ]);
  }
}

void main() {
  late _FakeCompanyRepository repository;

  setUp(() {
    repository = _FakeCompanyRepository();
  });

  group('CreateCompanyAndOwnerUseCase', () {
    test('returns the new company id on success', () async {
      final useCase = CreateCompanyAndOwnerUseCase(repository);
      final result = await useCase(name: 'JUMA Factory');
      expect(result, right<Failure, String>('company-1'));
      expect(repository.ownerCreated, isTrue);
    });

    test(
      'propagates a validation failure (e.g. already has a company)',
      () async {
        repository.failureToReturn = const ValidationFailure(
          'Сіз бұрын компанияға тіркелгенсіз',
        );
        final useCase = CreateCompanyAndOwnerUseCase(repository);
        final result = await useCase(name: 'JUMA Factory');
        expect(result.isLeft(), isTrue);
      },
    );
  });

  group('RequestToJoinCompanyUseCase', () {
    test('passes company code and requested role through unchanged', () async {
      final useCase = RequestToJoinCompanyUseCase(repository);
      final result = await useCase(
        companyCode: 'ABC1234',
        requestedRole: CompanyRole.manager,
      );
      expect(result, right<Failure, String>('request-1'));
      expect(repository.lastRequestedCompanyCode, 'ABC1234');
      expect(repository.lastRequestedRole, CompanyRole.manager);
    });

    test('a not-found company surfaces as NotFoundFailure', () async {
      repository.failureToReturn = const NotFoundFailure('Компания табылмады');
      final useCase = RequestToJoinCompanyUseCase(repository);
      final result = await useCase(
        companyCode: 'BADCODE',
        requestedRole: CompanyRole.manager,
      );
      expect(result.isLeft(), isTrue);
      result.match(
        (failure) => expect(failure, isA<NotFoundFailure>()),
        (_) {},
      );
    });
  });

  group('WithdrawCompanyJoinRequestUseCase', () {
    test('resolves to unit on success', () async {
      final useCase = WithdrawCompanyJoinRequestUseCase(repository);
      final result = await useCase('request-1');
      expect(result.isRight(), isTrue);
    });
  });

  group('GetPendingCompanyRequestsUseCase', () {
    test('returns the director own-company queue', () async {
      final useCase = GetPendingCompanyRequestsUseCase(repository);
      final result = await useCase();
      result.match((_) => fail('expected right'), (requests) {
        expect(requests, hasLength(1));
        expect(requests.first.fullName, 'Test User');
      });
    });
  });

  group('ApproveCompanyJoinRequestUseCase', () {
    test(
      'passes an override role through when the director changes it',
      () async {
        final useCase = ApproveCompanyJoinRequestUseCase(repository);
        await useCase('request-1', overrideRole: CompanyRole.warehouse);
        expect(repository.lastApprovedRequestId, 'request-1');
        expect(repository.lastOverrideRole, CompanyRole.warehouse);
      },
    );

    test(
      'a cross-company request id surfaces as NotFoundFailure (P0002)',
      () async {
        repository.failureToReturn = const NotFoundFailure('Сұраныс табылмады');
        final useCase = ApproveCompanyJoinRequestUseCase(repository);
        final result = await useCase('other-companys-request');
        result.match(
          (failure) => expect(failure, isA<NotFoundFailure>()),
          (_) => fail('expected left'),
        );
      },
    );
  });

  group('RejectCompanyJoinRequestUseCase', () {
    test('passes the rejection reason through', () async {
      final useCase = RejectCompanyJoinRequestUseCase(repository);
      await useCase('request-1', reason: 'Рөл сәйкес келмейді');
      expect(repository.lastRejectedRequestId, 'request-1');
      expect(repository.lastRejectionReason, 'Рөл сәйкес келмейді');
    });
  });

  group('CreateCompanyInvitationUseCase', () {
    test('returns the generated code and expiry', () async {
      final useCase = CreateCompanyInvitationUseCase(repository);
      final result = await useCase(role: CompanyRole.assistant);
      result.match((_) => fail('expected right'), (invitation) {
        expect(invitation.code, 'ABC12345');
      });
    });
  });

  group('AcceptCompanyInvitationUseCase', () {
    test('activates membership immediately, no approval step', () async {
      final useCase = AcceptCompanyInvitationUseCase(repository);
      final result = await useCase(code: 'ABC12345');
      expect(result, right<Failure, String>('company-1'));
      expect(repository.invitationAccepted, isTrue);
    });

    test(
      'an expired/reused invite surfaces as NotFoundFailure (P0002)',
      () async {
        repository.failureToReturn = const NotFoundFailure(
          'Шақыру коды жарамсыз немесе мерзімі өткен',
        );
        final useCase = AcceptCompanyInvitationUseCase(repository);
        final result = await useCase(code: 'EXPIRED1');
        result.match(
          (failure) => expect(failure, isA<NotFoundFailure>()),
          (_) => fail('expected left'),
        );
      },
    );
  });

  group('GetCompanySettingsUseCase', () {
    test('returns the caller\'s own company settings', () async {
      final useCase = GetCompanySettingsUseCase(repository);
      final result = await useCase();
      result.match(
        (_) => fail('expected right'),
        (settings) => expect(settings.name, 'Test Company'),
      );
    });
  });

  group('UpdateCompanySettingsUseCase', () {
    test('succeeds for a valid name', () async {
      final useCase = UpdateCompanySettingsUseCase(repository);
      final result = await useCase(name: 'Renamed Factory');
      expect(result.isRight(), isTrue);
    });

    test(
      'a non-director attempt surfaces as PermissionFailure (42501)',
      () async {
        repository.failureToReturn = const PermissionFailure();
        final useCase = UpdateCompanySettingsUseCase(repository);
        final result = await useCase(name: 'Renamed Factory');
        result.match(
          (failure) => expect(failure, isA<PermissionFailure>()),
          (_) => fail('expected left'),
        );
      },
    );
  });

  group('GetSubscriptionInfoUseCase', () {
    test('returns the caller\'s own plan/usage info', () async {
      final useCase = GetSubscriptionInfoUseCase(repository);
      final result = await useCase();
      result.match(
        (_) => fail('expected right'),
        (info) => expect(info.planKey, 'free'),
      );
    });
  });

  group('GetSubscriptionPlansUseCase', () {
    test('returns the plan catalog', () async {
      final useCase = GetSubscriptionPlansUseCase(repository);
      final result = await useCase();
      result.match(
        (_) => fail('expected right'),
        (plans) => expect(plans, isNotEmpty),
      );
    });
  });
}
