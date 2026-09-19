import '../../features/auth/domain/entities/profile_status.dart';
import 'route_paths.dart';

const _authScreens = {
  RoutePaths.login,
  RoutePaths.forgotPassword,
  RoutePaths.register,
};

const _onboardingChoiceScreens = {
  RoutePaths.onboarding,
  RoutePaths.onboardingCreateCompany,
  RoutePaths.onboardingJoinCompany,
};

/// The membership state machine behind the router's redirect guard —
/// a pure function of primitives (no `BuildContext`/`GoRouterState`),
/// so it's directly unit-testable. See
/// supabase/README.md's "Company registration" section for the
/// backing SQL; this is UX convenience only, same as the pre-existing
/// session-only guard it replaces — the real authorization boundary is
/// always Supabase RLS, never this function.
///
/// States, in the order they're checked:
/// 1. no session -> [RoutePaths.login] (unless already on an auth
///    screen, or on [RoutePaths.registerVerify] with a genuinely
///    in-flight dual-contact registration — see [hasPendingRegistration])
/// 2. `companyId == null` and `!contactsVerified` ->
///    [RoutePaths.registerVerify] (dual-contact registration's email/
///    phone verification step must finish before onboarding — see
///    RegistrationVerifyScreen; this never applies to an
///    already-onboarded account, only while `companyId` is still null)
/// 3. `companyId == null` -> [RoutePaths.onboarding] (fresh signup, or
///    a withdrawn/never-submitted request)
/// 4. `status == pending` -> [RoutePaths.waitingApproval]
/// 5. `status == rejected` -> back to the onboarding choice (re-request
///    allowed — see `request_to_join_company()`'s own precondition)
/// 6. `status == suspended` or `!companyIsActive` -> [RoutePaths.accessBlocked]
/// 7. `status == active` and the company is active -> into the shell;
///    bounced off any auth/onboarding/waiting/blocked screen still
///    matched from a stale deep link.
String? resolveOnboardingRedirect({
  required bool loggedIn,
  required String matchedLocation,
  required bool hasPendingRegistration,
  required bool contactsVerified,
  required String? companyId,
  required ProfileStatus? status,
  required bool companyIsActive,
  bool profileLoaded = true,
}) {
  final onAuthScreen = _authScreens.contains(matchedLocation);

  if (!loggedIn) {
    if (matchedLocation == RoutePaths.registerVerify &&
        hasPendingRegistration) {
      // Email confirmation is still pending and the app has no session
      // yet — this is the one screen a logged-out user is allowed to
      // stay on outside of login/register, so they can re-enter their
      // password once they've clicked the confirmation link (see
      // EmailConfirmationPendingScreen's `needsPassword` case).
      return null;
    }
    return onAuthScreen ? null : RoutePaths.login;
  }

  if (!profileLoaded) return null;

  if (companyId == null) {
    if (!contactsVerified) {
      return matchedLocation == RoutePaths.registerVerify
          ? null
          : RoutePaths.registerVerify;
    }
    return _onboardingChoiceScreens.contains(matchedLocation)
        ? null
        : RoutePaths.onboarding;
  }

  if (status == ProfileStatus.pending) {
    return matchedLocation == RoutePaths.waitingApproval
        ? null
        : RoutePaths.waitingApproval;
  }

  if (status == ProfileStatus.rejected) {
    return _onboardingChoiceScreens.contains(matchedLocation)
        ? null
        : RoutePaths.onboarding;
  }

  if (status == ProfileStatus.suspended || !companyIsActive) {
    return matchedLocation == RoutePaths.accessBlocked
        ? null
        : RoutePaths.accessBlocked;
  }

  // status == active && companyIsActive
  final onNonShellScreen =
      onAuthScreen ||
      matchedLocation == RoutePaths.registerVerify ||
      _onboardingChoiceScreens.contains(matchedLocation) ||
      matchedLocation == RoutePaths.waitingApproval ||
      matchedLocation == RoutePaths.accessBlocked;
  return onNonShellScreen ? RoutePaths.dashboard : null;
}
