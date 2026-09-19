import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:http/http.dart' as http;
import 'package:juma_ui_crm/core/error/failures.dart';
import 'package:juma_ui_crm/core/providers/supabase_provider.dart';
import 'package:juma_ui_crm/features/company/domain/entities/company_invitation.dart';
import 'package:juma_ui_crm/features/company/domain/entities/company_join_request.dart';
import 'package:juma_ui_crm/features/company/domain/entities/company_settings.dart';
import 'package:juma_ui_crm/features/company/domain/entities/company_subscription_info.dart';
import 'package:juma_ui_crm/features/company/domain/entities/pending_company_request.dart';
import 'package:juma_ui_crm/features/company/domain/entities/subscription_plan.dart';
import 'package:juma_ui_crm/features/company/domain/repositories/company_repository.dart';
import 'package:juma_ui_crm/features/company/domain/value_objects/company_role.dart';
import 'package:juma_ui_crm/features/company/presentation/providers/company_providers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Same hand-written-fake approach as company_usecases_test.dart — no
/// mocking framework exists in this codebase.
class _FakeCompanyRepository implements CompanyRepository {
  Failure? failureToReturn;

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
    return right('company-1');
  }

  @override
  Future<Either<Failure, String>> requestToJoinCompany({
    required String companyCode,
    required CompanyRole requestedRole,
    String? message,
  }) async {
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
    return right(const []);
  }

  @override
  Future<Either<Failure, List<PendingCompanyRequest>>>
  getPendingCompanyRequests() async {
    return right(const []);
  }

  @override
  Future<Either<Failure, Unit>> approveCompanyJoinRequest(
    String requestId, {
    CompanyRole? overrideRole,
  }) async {
    if (failureToReturn != null) return left(failureToReturn!);
    return right(unit);
  }

  @override
  Future<Either<Failure, Unit>> rejectCompanyJoinRequest(
    String requestId, {
    String? reason,
  }) async {
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
      CompanyInvitation(code: 'XYZ98765', expiresAt: DateTime(2026, 3)),
    );
  }

  @override
  Future<Either<Failure, String>> acceptCompanyInvitation({
    required String code,
    String? message,
  }) async {
    if (failureToReturn != null) return left(failureToReturn!);
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

/// Stands in for the real Supabase auth HTTP transport so
/// `auth.refreshSession()` can complete against a real [SupabaseClient]
/// without a network call. Only understands the one request GoTrue
/// issues for a token refresh (`POST .../auth/v1/token?grant_type=
/// refresh_token`) — any other request is a test-setup bug, not
/// something to fake silently.
class _RecordingAuthHttpClient extends http.BaseClient {
  int refreshCallCount = 0;
  final http.Client _inner = http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (request.method == 'POST' &&
        request.url.path.endsWith('/token') &&
        request.url.queryParameters['grant_type'] == 'refresh_token') {
      refreshCallCount++;
      final body = jsonEncode({
        'access_token': 'test-access-token-refreshed',
        'token_type': 'bearer',
        'expires_in': 3600,
        'refresh_token': 'test-refresh-token-refreshed',
        'user': {'id': 'test-user-1', 'aud': 'authenticated'},
      });
      return http.StreamedResponse(
        Stream.value(utf8.encode(body)),
        200,
        headers: {'content-type': 'application/json'},
      );
    }
    throw StateError(
      'Unexpected HTTP request in test: ${request.method} ${request.url}',
    );
  }

  @override
  void close() => _inner.close();
}

void main() {
  late _FakeCompanyRepository repository;
  late _RecordingAuthHttpClient authHttpClient;
  late SupabaseClient supabaseClient;
  late ProviderContainer container;

  setUp(() async {
    repository = _FakeCompanyRepository();
    authHttpClient = _RecordingAuthHttpClient();
    // A real SupabaseClient wired to the fake transport above — needed
    // because CreateCompanyController.submit() now calls
    // ref.read(supabaseClientProvider).auth.refreshSession() on
    // success (see onboarding_redirect_test.dart's sibling coverage of
    // *why*: GoRouter's redirect guard reads a cached profile that
    // only becomes fresh again once a real onAuthStateChange event
    // fires, which refreshSession() is what produces).
    supabaseClient = SupabaseClient(
      'https://test.supabase.co',
      'test-anon-key',
      httpClient: authHttpClient,
    );
    // Seeds a session locally (no network call: a non-JWT access
    // token makes Session.isExpired resolve to false) so
    // refreshSession() has a session/refresh token to act on instead
    // of throwing AuthSessionMissingException.
    await supabaseClient.auth.recoverSession(
      jsonEncode({
        'access_token': 'test-access-token',
        'token_type': 'bearer',
        'refresh_token': 'test-refresh-token',
        'user': {'id': 'test-user-1', 'aud': 'authenticated'},
      }),
    );
    container = ProviderContainer(
      overrides: [
        companyRepositoryProvider.overrideWithValue(repository),
        supabaseClientProvider.overrideWithValue(supabaseClient),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(supabaseClient.dispose);
  });

  group('CreateCompanyController', () {
    test('submit() returns null and settles to AsyncData on success', () async {
      final failure = await container
          .read(createCompanyControllerProvider.notifier)
          .submit(name: 'JUMA Factory');
      expect(failure, isNull);
      expect(container.read(createCompanyControllerProvider).hasError, isFalse);
    });

    test('submit() returns the failure on error', () async {
      repository.failureToReturn = const ValidationFailure(
        'Компания атауын енгізіңіз',
      );
      final failure = await container
          .read(createCompanyControllerProvider.notifier)
          .submit(name: '');
      expect(failure, isA<ValidationFailure>());
    });

    test(
      'submit() refreshes the session on success, so authStateProvider '
      'reloads a fresh profile before the caller navigates to /dashboard',
      () async {
        final failure = await container
            .read(createCompanyControllerProvider.notifier)
            .submit(name: 'JUMA Factory');
        expect(failure, isNull);
        expect(authHttpClient.refreshCallCount, 1);
      },
    );

    test('submit() does NOT refresh the session when the RPC fails', () async {
      repository.failureToReturn = const ValidationFailure(
        'Компания атауын енгізіңіз',
      );
      final failure = await container
          .read(createCompanyControllerProvider.notifier)
          .submit(name: '');
      expect(failure, isA<ValidationFailure>());
      expect(authHttpClient.refreshCallCount, 0);
    });
  });

  group('MembershipController', () {
    test('requestToJoin() succeeds with no failure', () async {
      final failure = await container
          .read(membershipControllerProvider.notifier)
          .requestToJoin(
            companyCode: 'ABC1234',
            requestedRole: CompanyRole.manager,
          );
      expect(failure, isNull);
    });

    test('acceptInvitation() succeeds with no failure', () async {
      final failure = await container
          .read(membershipControllerProvider.notifier)
          .acceptInvitation(code: 'XYZ98765');
      expect(failure, isNull);
    });

    test('withdraw() surfaces a failure', () async {
      repository.failureToReturn = const ValidationFailure(
        'Сұранысты қайтарып алу мүмкін емес',
      );
      final failure = await container
          .read(membershipControllerProvider.notifier)
          .withdraw('request-1');
      expect(failure, isA<ValidationFailure>());
    });
  });

  group('CompanyRequestActionController', () {
    test('approve() succeeds with no failure', () async {
      final failure = await container
          .read(companyRequestActionControllerProvider.notifier)
          .approve('request-1');
      expect(failure, isNull);
    });

    test('reject() surfaces a cross-company NotFoundFailure', () async {
      repository.failureToReturn = const NotFoundFailure('Сұраныс табылмады');
      final failure = await container
          .read(companyRequestActionControllerProvider.notifier)
          .reject('request-1', reason: 'test');
      expect(failure, isA<NotFoundFailure>());
    });
  });

  group('CreateInvitationController', () {
    test('create() stores the invitation in state on success', () async {
      final failure = await container
          .read(createInvitationControllerProvider.notifier)
          .create(role: CompanyRole.assistant);
      expect(failure, isNull);
      final state = container.read(createInvitationControllerProvider);
      expect(state.value?.code, 'XYZ98765');
    });

    test('create() leaves state null on failure', () async {
      repository.failureToReturn = const PermissionFailure();
      final failure = await container
          .read(createInvitationControllerProvider.notifier)
          .create(role: CompanyRole.assistant);
      expect(failure, isA<PermissionFailure>());
      final state = container.read(createInvitationControllerProvider);
      expect(state.value, isNull);
    });
  });

  group('companySettingsProvider', () {
    test('resolves to the caller\'s own company settings', () async {
      final settings = await container.read(companySettingsProvider.future);
      expect(settings.name, 'Test Company');
    });
  });

  group('subscriptionInfoProvider', () {
    test('resolves to the caller\'s own plan/usage info', () async {
      final info = await container.read(subscriptionInfoProvider.future);
      expect(info.planKey, 'free');
      expect(info.activeUsers, 1);
    });
  });

  group('subscriptionPlansProvider', () {
    test('resolves to the plan catalog', () async {
      final plans = await container.read(subscriptionPlansProvider.future);
      expect(plans, isNotEmpty);
    });
  });

  group('UpdateCompanySettingsController', () {
    test('submit() succeeds with no failure', () async {
      final failure = await container
          .read(updateCompanySettingsControllerProvider.notifier)
          .submit(name: 'Renamed Factory');
      expect(failure, isNull);
    });

    test('submit() surfaces a permission failure for a non-director', () async {
      repository.failureToReturn = const PermissionFailure();
      final failure = await container
          .read(updateCompanySettingsControllerProvider.notifier)
          .submit(name: 'Renamed Factory');
      expect(failure, isA<PermissionFailure>());
    });
  });
}
