import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../../../../core/realtime/table_realtime_provider.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/company_remote_datasource.dart';
import '../../data/repositories/company_repository_impl.dart';
import '../../domain/entities/company_invitation.dart';
import '../../domain/entities/company_join_request.dart';
import '../../domain/entities/company_settings.dart';
import '../../domain/entities/company_subscription_info.dart';
import '../../domain/entities/pending_company_request.dart';
import '../../domain/entities/subscription_plan.dart';
import '../../domain/repositories/company_repository.dart';
import '../../domain/usecases/accept_company_invitation_usecase.dart';
import '../../domain/usecases/approve_company_join_request_usecase.dart';
import '../../domain/usecases/create_company_and_owner_usecase.dart';
import '../../domain/usecases/create_company_invitation_usecase.dart';
import '../../domain/usecases/get_company_settings_usecase.dart';
import '../../domain/usecases/get_my_join_requests_usecase.dart';
import '../../domain/usecases/get_pending_company_requests_usecase.dart';
import '../../domain/usecases/get_subscription_info_usecase.dart';
import '../../domain/usecases/get_subscription_plans_usecase.dart';
import '../../domain/usecases/reject_company_join_request_usecase.dart';
import '../../domain/usecases/request_to_join_company_usecase.dart';
import '../../domain/usecases/update_company_settings_usecase.dart';
import '../../domain/usecases/withdraw_company_join_request_usecase.dart';
import '../../domain/value_objects/company_role.dart';

final companyRemoteDataSourceProvider = Provider<CompanyRemoteDataSource>((
  ref,
) {
  return CompanyRemoteDataSource(ref.watch(supabaseClientProvider));
});

final companyRepositoryProvider = Provider<CompanyRepository>((ref) {
  return CompanyRepositoryImpl(ref.watch(companyRemoteDataSourceProvider));
});

final createCompanyAndOwnerUseCaseProvider =
    Provider<CreateCompanyAndOwnerUseCase>((ref) {
      return CreateCompanyAndOwnerUseCase(ref.watch(companyRepositoryProvider));
    });

final requestToJoinCompanyUseCaseProvider =
    Provider<RequestToJoinCompanyUseCase>((ref) {
      return RequestToJoinCompanyUseCase(ref.watch(companyRepositoryProvider));
    });

final withdrawCompanyJoinRequestUseCaseProvider =
    Provider<WithdrawCompanyJoinRequestUseCase>((ref) {
      return WithdrawCompanyJoinRequestUseCase(
        ref.watch(companyRepositoryProvider),
      );
    });

final getMyJoinRequestsUseCaseProvider = Provider<GetMyJoinRequestsUseCase>((
  ref,
) {
  return GetMyJoinRequestsUseCase(ref.watch(companyRepositoryProvider));
});

final getPendingCompanyRequestsUseCaseProvider =
    Provider<GetPendingCompanyRequestsUseCase>((ref) {
      return GetPendingCompanyRequestsUseCase(
        ref.watch(companyRepositoryProvider),
      );
    });

final approveCompanyJoinRequestUseCaseProvider =
    Provider<ApproveCompanyJoinRequestUseCase>((ref) {
      return ApproveCompanyJoinRequestUseCase(
        ref.watch(companyRepositoryProvider),
      );
    });

final rejectCompanyJoinRequestUseCaseProvider =
    Provider<RejectCompanyJoinRequestUseCase>((ref) {
      return RejectCompanyJoinRequestUseCase(
        ref.watch(companyRepositoryProvider),
      );
    });

final createCompanyInvitationUseCaseProvider =
    Provider<CreateCompanyInvitationUseCase>((ref) {
      return CreateCompanyInvitationUseCase(
        ref.watch(companyRepositoryProvider),
      );
    });

final acceptCompanyInvitationUseCaseProvider =
    Provider<AcceptCompanyInvitationUseCase>((ref) {
      return AcceptCompanyInvitationUseCase(
        ref.watch(companyRepositoryProvider),
      );
    });

/// The signed-in caller's own join-request history — backs the
/// Waiting Approval screen.
final myJoinRequestsProvider =
    FutureProvider.autoDispose<List<CompanyJoinRequest>>((ref) {
      return ref
          .watch(getMyJoinRequestsUseCaseProvider)
          .call()
          .then(
            (either) =>
                either.match((failure) => throw failure, (data) => data),
          );
    });

/// The caller's own company's incoming pending requests —
/// director/owner only server-side; this provider is only ever
/// watched from a director-gated screen (UI convenience, not the real
/// gate — see get_pending_company_requests()'s own auth_is_director()
/// check).
final pendingCompanyRequestsProvider =
    FutureProvider.autoDispose<List<PendingCompanyRequest>>((ref) {
      return ref
          .watch(getPendingCompanyRequestsUseCaseProvider)
          .call()
          .then(
            (either) =>
                either.match((failure) => throw failure, (data) => data),
          );
    });

/// Requester-side membership actions (create company is separate — see
/// [CreateCompanyController]): request to join, withdraw a pending
/// request, redeem an invitation. Grouped together since they all
/// mutate the same "my own membership" state the router redirect
/// reacts to via [authStateProvider].
class MembershipController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<Failure?> requestToJoin({
    required String companyCode,
    required CompanyRole requestedRole,
    String? message,
  }) async {
    state = const AsyncLoading();
    final result = await ref
        .read(requestToJoinCompanyUseCaseProvider)
        .call(
          companyCode: companyCode,
          requestedRole: requestedRole,
          message: message,
        );
    return result.match(
      (failure) {
        state = const AsyncData(null);
        return failure;
      },
      (_) {
        state = const AsyncData(null);
        return null;
      },
    );
  }

  Future<Failure?> acceptInvitation({
    required String code,
    String? message,
  }) async {
    state = const AsyncLoading();
    final result = await ref
        .read(acceptCompanyInvitationUseCaseProvider)
        .call(code: code, message: message);
    return result.match(
      (failure) {
        state = const AsyncData(null);
        return failure;
      },
      (_) {
        state = const AsyncData(null);
        return null;
      },
    );
  }

  Future<Failure?> withdraw(String requestId) async {
    state = const AsyncLoading();
    final result = await ref
        .read(withdrawCompanyJoinRequestUseCaseProvider)
        .call(requestId);
    return result.match(
      (failure) {
        state = const AsyncData(null);
        return failure;
      },
      (_) {
        state = const AsyncData(null);
        return null;
      },
    );
  }
}

final membershipControllerProvider =
    AsyncNotifierProvider<MembershipController, void>(MembershipController.new);

/// Company-creation is kept separate from [MembershipController]
/// because the auth flow (SignUpScreen) may also need to distinguish
/// "still creating a company" from "already have one" without pulling
/// in the requester-side actions above.
class CreateCompanyController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<Failure?> submit({
    required String name,
    String? phone,
    String? email,
    String? city,
    String? address,
    String? iinBin,
  }) async {
    state = const AsyncLoading();
    final result = await ref
        .read(createCompanyAndOwnerUseCaseProvider)
        .call(
          name: name,
          phone: phone,
          email: email,
          city: city,
          address: address,
          iinBin: iinBin,
        );
    return result.match(
      (failure) {
        state = const AsyncData(null);
        return failure;
      },
      (_) async {
        // Forces a genuine onAuthStateChange event so authStateProvider
        // reloads the now-populated company_id/status before the caller
        // navigates — same pattern as myMembershipRealtimeProvider above.
        await ref.read(supabaseClientProvider).auth.refreshSession();
        state = const AsyncData(null);
        return null;
      },
    );
  }
}

final createCompanyControllerProvider =
    AsyncNotifierProvider<CreateCompanyController, void>(
      CreateCompanyController.new,
    );

/// Director/owner-side decisions on an incoming request.
class CompanyRequestActionController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<Failure?> approve(
    String requestId, {
    CompanyRole? overrideRole,
  }) async {
    state = const AsyncLoading();
    final result = await ref
        .read(approveCompanyJoinRequestUseCaseProvider)
        .call(requestId, overrideRole: overrideRole);
    return result.match(
      (failure) {
        state = const AsyncData(null);
        return failure;
      },
      (_) {
        state = const AsyncData(null);
        return null;
      },
    );
  }

  Future<Failure?> reject(String requestId, {String? reason}) async {
    state = const AsyncLoading();
    final result = await ref
        .read(rejectCompanyJoinRequestUseCaseProvider)
        .call(requestId, reason: reason);
    return result.match(
      (failure) {
        state = const AsyncData(null);
        return failure;
      },
      (_) {
        state = const AsyncData(null);
        return null;
      },
    );
  }
}

final companyRequestActionControllerProvider =
    AsyncNotifierProvider<CompanyRequestActionController, void>(
      CompanyRequestActionController.new,
    );

/// Holds the most recently created invite code so InviteEmployeeScreen
/// can show it (text + QR) after [create] succeeds.
class CreateInvitationController extends AsyncNotifier<CompanyInvitation?> {
  @override
  Future<CompanyInvitation?> build() async => null;

  Future<Failure?> create({
    required CompanyRole role,
    int maxUses = 1,
    int expiresInHours = 168,
  }) async {
    state = const AsyncLoading();
    final result = await ref
        .read(createCompanyInvitationUseCaseProvider)
        .call(role: role, maxUses: maxUses, expiresInHours: expiresInHours);
    return result.match(
      (failure) {
        state = const AsyncData(null);
        return failure;
      },
      (invitation) {
        state = AsyncData(invitation);
        return null;
      },
    );
  }
}

final createInvitationControllerProvider =
    AsyncNotifierProvider<CreateInvitationController, CompanyInvitation?>(
      CreateInvitationController.new,
    );

final getCompanySettingsUseCaseProvider = Provider<GetCompanySettingsUseCase>((
  ref,
) {
  return GetCompanySettingsUseCase(ref.watch(companyRepositoryProvider));
});

final updateCompanySettingsUseCaseProvider =
    Provider<UpdateCompanySettingsUseCase>((ref) {
      return UpdateCompanySettingsUseCase(ref.watch(companyRepositoryProvider));
    });

final getSubscriptionInfoUseCaseProvider = Provider<GetSubscriptionInfoUseCase>(
  (ref) {
    return GetSubscriptionInfoUseCase(ref.watch(companyRepositoryProvider));
  },
);

final getSubscriptionPlansUseCaseProvider =
    Provider<GetSubscriptionPlansUseCase>((ref) {
      return GetSubscriptionPlansUseCase(ref.watch(companyRepositoryProvider));
    });

/// The caller's own company's settings — Stage 3 (Company Settings &
/// Subscription Management).
final companySettingsProvider = FutureProvider.autoDispose<CompanySettings>((
  ref,
) {
  return ref
      .watch(getCompanySettingsUseCaseProvider)
      .call()
      .then(
        (either) => either.match((failure) => throw failure, (data) => data),
      );
});

final subscriptionInfoProvider =
    FutureProvider.autoDispose<CompanySubscriptionInfo>((ref) {
      return ref
          .watch(getSubscriptionInfoUseCaseProvider)
          .call()
          .then(
            (either) =>
                either.match((failure) => throw failure, (data) => data),
          );
    });

final subscriptionPlansProvider =
    FutureProvider.autoDispose<List<SubscriptionPlan>>((ref) {
      return ref
          .watch(getSubscriptionPlansUseCaseProvider)
          .call()
          .then(
            (either) =>
                either.match((failure) => throw failure, (data) => data),
          );
    });

class UpdateCompanySettingsController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<Failure?> submit({
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
    state = const AsyncLoading();
    final result = await ref
        .read(updateCompanySettingsUseCaseProvider)
        .call(
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
    return result.match(
      (failure) {
        state = const AsyncData(null);
        return failure;
      },
      (_) {
        state = const AsyncData(null);
        return null;
      },
    );
  }
}

final updateCompanySettingsControllerProvider =
    AsyncNotifierProvider<UpdateCompanySettingsController, void>(
      UpdateCompanySettingsController.new,
    );

/// Stage 4 Part 1 — "Join Requests" realtime. `company_join_requests`
/// has all direct grants revoked (RPC-only, see
/// 20260713000036's own header comment), so it's proxied through
/// `profiles` the same way `employeesRealtimeProvider` is: every join-
/// request action (submit/withdraw/approve/reject) also writes
/// `profiles.company_id`/`status` via the onboarding RPCs. Refreshes
/// both sides of the flow — the director's incoming queue and the
/// requester's own status.
final joinRequestsRealtimeProvider = tableRealtimeProvider('profiles', (ref) {
  ref.invalidate(pendingCompanyRequestsProvider);
  ref.invalidate(myJoinRequestsProvider);
});

/// WaitingApprovalScreen's own subscription — replaces the 8-second
/// `Timer.periodic` poll that screen used before Realtime existed
/// (Stage 4 Part 1: "remove unnecessary polling"). On top of what
/// [joinRequestsRealtimeProvider] already does, this ALSO forces a
/// session refresh: `refreshSession()` always fires a genuine
/// `onAuthStateChange` event on success, which `authStateProvider`'s
/// existing subscription reloads the profile from, and which
/// `GoRouterRefreshStream` (bound to that same stream) reacts to by
/// re-evaluating the redirect guard — so the moment a director
/// approves/rejects this request elsewhere, this screen is carried
/// straight to the dashboard (or back to onboarding) by the router
/// itself, no manual `context.go` needed here.
final myMembershipRealtimeProvider = tableRealtimeProvider('profiles', (ref) {
  ref.invalidate(myJoinRequestsProvider);
  unawaited(ref.read(supabaseClientProvider).auth.refreshSession());
});

/// Stage 4 Part 1 — "Subscription status" realtime. Both `companies`
/// (is_active/subscription_plan) and `company_subscriptions` (the
/// actual history row) can change what `get_company_subscription_info()`
/// returns.
final companiesRealtimeProvider = tableRealtimeProvider('companies', (ref) {
  ref.invalidate(subscriptionInfoProvider);
});

final companySubscriptionsRealtimeProvider = tableRealtimeProvider(
  'company_subscriptions',
  (ref) => ref.invalidate(subscriptionInfoProvider),
);
