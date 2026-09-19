import 'package:flutter_test/flutter_test.dart';
import 'package:juma_ui_crm/core/router/onboarding_redirect.dart';
import 'package:juma_ui_crm/core/router/route_paths.dart';
import 'package:juma_ui_crm/features/auth/domain/entities/profile_status.dart';

void main() {
  group('resolveOnboardingRedirect', () {
    test(
      'session arriving before profile does not trigger SMS verification',
      () {
        expect(
          resolveOnboardingRedirect(
            loggedIn: true,
            profileLoaded: false,
            matchedLocation: RoutePaths.login,
            hasPendingRegistration: false,
            contactsVerified: false,
            companyId: null,
            status: null,
            companyIsActive: true,
          ),
          isNull,
        );
        expect(
          resolveOnboardingRedirect(
            loggedIn: true,
            profileLoaded: true,
            matchedLocation: RoutePaths.registerVerify,
            hasPendingRegistration: false,
            contactsVerified: false,
            companyId: 'development-company',
            status: ProfileStatus.active,
            companyIsActive: true,
          ),
          RoutePaths.dashboard,
        );
      },
    );
    test('no session on a non-auth screen redirects to login', () {
      final result = resolveOnboardingRedirect(
        loggedIn: false,
        hasPendingRegistration: false,
        contactsVerified: true,
        matchedLocation: RoutePaths.dashboard,
        companyId: null,
        status: null,
        companyIsActive: true,
      );
      expect(result, RoutePaths.login);
    });

    test('no session on an auth screen is left alone', () {
      final result = resolveOnboardingRedirect(
        loggedIn: false,
        hasPendingRegistration: false,
        contactsVerified: true,
        matchedLocation: RoutePaths.register,
        companyId: null,
        status: null,
        companyIsActive: true,
      );
      expect(result, isNull);
    });

    test('signed in with no company redirects to onboarding choice', () {
      final result = resolveOnboardingRedirect(
        loggedIn: true,
        hasPendingRegistration: false,
        contactsVerified: true,
        matchedLocation: RoutePaths.dashboard,
        companyId: null,
        status: ProfileStatus.pending,
        companyIsActive: true,
      );
      expect(result, RoutePaths.onboarding);
    });

    test('no company but already on create-company screen is left alone', () {
      final result = resolveOnboardingRedirect(
        loggedIn: true,
        hasPendingRegistration: false,
        contactsVerified: true,
        matchedLocation: RoutePaths.onboardingCreateCompany,
        companyId: null,
        status: ProfileStatus.pending,
        companyIsActive: true,
      );
      expect(result, isNull);
    });

    test('pending membership redirects to waiting approval', () {
      final result = resolveOnboardingRedirect(
        loggedIn: true,
        hasPendingRegistration: false,
        contactsVerified: true,
        matchedLocation: RoutePaths.dashboard,
        companyId: 'company-1',
        status: ProfileStatus.pending,
        companyIsActive: true,
      );
      expect(result, RoutePaths.waitingApproval);
    });

    test('pending membership already on waiting screen is left alone', () {
      final result = resolveOnboardingRedirect(
        loggedIn: true,
        hasPendingRegistration: false,
        contactsVerified: true,
        matchedLocation: RoutePaths.waitingApproval,
        companyId: 'company-1',
        status: ProfileStatus.pending,
        companyIsActive: true,
      );
      expect(result, isNull);
    });

    test('rejected membership redirects back to onboarding choice', () {
      final result = resolveOnboardingRedirect(
        loggedIn: true,
        hasPendingRegistration: false,
        contactsVerified: true,
        matchedLocation: RoutePaths.dashboard,
        companyId: 'company-1',
        status: ProfileStatus.rejected,
        companyIsActive: true,
      );
      expect(result, RoutePaths.onboarding);
    });

    test(
      'rejected membership already on join-company screen is left alone',
      () {
        final result = resolveOnboardingRedirect(
          loggedIn: true,
          hasPendingRegistration: false,
          contactsVerified: true,
          matchedLocation: RoutePaths.onboardingJoinCompany,
          companyId: 'company-1',
          status: ProfileStatus.rejected,
          companyIsActive: true,
        );
        expect(result, isNull);
      },
    );

    test('suspended profile redirects to access-blocked', () {
      final result = resolveOnboardingRedirect(
        loggedIn: true,
        hasPendingRegistration: false,
        contactsVerified: true,
        matchedLocation: RoutePaths.dashboard,
        companyId: 'company-1',
        status: ProfileStatus.suspended,
        companyIsActive: true,
      );
      expect(result, RoutePaths.accessBlocked);
    });

    test('inactive company redirects to access-blocked even if active', () {
      final result = resolveOnboardingRedirect(
        loggedIn: true,
        hasPendingRegistration: false,
        contactsVerified: true,
        matchedLocation: RoutePaths.dashboard,
        companyId: 'company-1',
        status: ProfileStatus.active,
        companyIsActive: false,
      );
      expect(result, RoutePaths.accessBlocked);
    });

    test('blocked state already on access-blocked screen is left alone', () {
      final result = resolveOnboardingRedirect(
        loggedIn: true,
        hasPendingRegistration: false,
        contactsVerified: true,
        matchedLocation: RoutePaths.accessBlocked,
        companyId: 'company-1',
        status: ProfileStatus.suspended,
        companyIsActive: true,
      );
      expect(result, isNull);
    });

    test('active membership + active company on dashboard is left alone', () {
      final result = resolveOnboardingRedirect(
        loggedIn: true,
        hasPendingRegistration: false,
        contactsVerified: true,
        matchedLocation: RoutePaths.dashboard,
        companyId: 'company-1',
        status: ProfileStatus.active,
        companyIsActive: true,
      );
      expect(result, isNull);
    });

    test('active membership on login screen redirects to dashboard', () {
      final result = resolveOnboardingRedirect(
        loggedIn: true,
        hasPendingRegistration: false,
        contactsVerified: true,
        matchedLocation: RoutePaths.login,
        companyId: 'company-1',
        status: ProfileStatus.active,
        companyIsActive: true,
      );
      expect(result, RoutePaths.dashboard);
    });

    test(
      'active membership on waiting-approval screen redirects to dashboard',
      () {
        final result = resolveOnboardingRedirect(
          loggedIn: true,
          hasPendingRegistration: false,
          contactsVerified: true,
          matchedLocation: RoutePaths.waitingApproval,
          companyId: 'company-1',
          status: ProfileStatus.active,
          companyIsActive: true,
        );
        expect(result, RoutePaths.dashboard);
      },
    );

    test(
      'active membership on stale onboarding-choice screen redirects to dashboard',
      () {
        final result = resolveOnboardingRedirect(
          loggedIn: true,
          hasPendingRegistration: false,
          contactsVerified: true,
          matchedLocation: RoutePaths.onboarding,
          companyId: 'company-1',
          status: ProfileStatus.active,
          companyIsActive: true,
        );
        expect(result, RoutePaths.dashboard);
      },
    );

    test('active membership deep inside the shell is left alone', () {
      final result = resolveOnboardingRedirect(
        loggedIn: true,
        hasPendingRegistration: false,
        contactsVerified: true,
        matchedLocation: RoutePaths.employees,
        companyId: 'company-1',
        status: ProfileStatus.active,
        companyIsActive: true,
      );
      expect(result, isNull);
    });

    test('active membership on Company Settings (Stage 3) is left alone', () {
      final result = resolveOnboardingRedirect(
        loggedIn: true,
        hasPendingRegistration: false,
        contactsVerified: true,
        matchedLocation: RoutePaths.companySettings,
        companyId: 'company-1',
        status: ProfileStatus.active,
        companyIsActive: true,
      );
      expect(result, isNull);
    });

    test('active membership on Subscription (Stage 3) is left alone', () {
      final result = resolveOnboardingRedirect(
        loggedIn: true,
        hasPendingRegistration: false,
        contactsVerified: true,
        matchedLocation: RoutePaths.subscription,
        companyId: 'company-1',
        status: ProfileStatus.active,
        companyIsActive: true,
      );
      expect(result, isNull);
    });

    test('active membership on Billing (Stage 3) is left alone', () {
      final result = resolveOnboardingRedirect(
        loggedIn: true,
        hasPendingRegistration: false,
        contactsVerified: true,
        matchedLocation: RoutePaths.billing,
        companyId: 'company-1',
        status: ProfileStatus.active,
        companyIsActive: true,
      );
      expect(result, isNull);
    });

    test(
      'a suspended director is still bounced off Company Settings by the router '
      '(the RPC itself still allows director-only edits; only SubscriptionGuard, '
      'not this redirect, is where the Payments-page director exception lives)',
      () {
        final result = resolveOnboardingRedirect(
          loggedIn: true,
          hasPendingRegistration: false,
          contactsVerified: true,
          matchedLocation: RoutePaths.companySettings,
          companyId: 'company-1',
          status: ProfileStatus.suspended,
          companyIsActive: true,
        );
        expect(result, RoutePaths.accessBlocked);
      },
    );

    group('dual-contact registration verification gate', () {
      test(
        'signed in, no company yet, contacts unverified redirects to register-verify',
        () {
          final result = resolveOnboardingRedirect(
            loggedIn: true,
            hasPendingRegistration: false,
            contactsVerified: false,
            matchedLocation: RoutePaths.dashboard,
            companyId: null,
            status: null,
            companyIsActive: true,
          );
          expect(result, RoutePaths.registerVerify);
        },
      );

      test(
        'signed in, no company yet, already on register-verify is left alone',
        () {
          final result = resolveOnboardingRedirect(
            loggedIn: true,
            hasPendingRegistration: false,
            contactsVerified: false,
            matchedLocation: RoutePaths.registerVerify,
            companyId: null,
            status: null,
            companyIsActive: true,
          );
          expect(result, isNull);
        },
      );

      test(
        'signed in, no company yet, contacts verified proceeds to onboarding choice '
        'instead of register-verify',
        () {
          final result = resolveOnboardingRedirect(
            loggedIn: true,
            hasPendingRegistration: false,
            contactsVerified: true,
            matchedLocation: RoutePaths.dashboard,
            companyId: null,
            status: null,
            companyIsActive: true,
          );
          expect(result, RoutePaths.onboarding);
        },
      );

      test('an already-onboarded account (company_id set) is never sent to '
          'register-verify even if contactsVerified is false — the gate only '
          'applies during the pre-onboarding window, so pre-existing/director-'
          'provisioned accounts are unaffected', () {
        final result = resolveOnboardingRedirect(
          loggedIn: true,
          hasPendingRegistration: false,
          contactsVerified: false,
          matchedLocation: RoutePaths.dashboard,
          companyId: 'company-1',
          status: ProfileStatus.active,
          companyIsActive: true,
        );
        expect(result, isNull);
      });

      test(
        'no session but a pending registration is in flight stays on '
        'register-verify (re-entering the password after email confirmation)',
        () {
          final result = resolveOnboardingRedirect(
            loggedIn: false,
            hasPendingRegistration: true,
            contactsVerified: false,
            matchedLocation: RoutePaths.registerVerify,
            companyId: null,
            status: null,
            companyIsActive: true,
          );
          expect(result, isNull);
        },
      );

      test(
        'no session and no pending registration on register-verify redirects to login',
        () {
          final result = resolveOnboardingRedirect(
            loggedIn: false,
            hasPendingRegistration: false,
            contactsVerified: false,
            matchedLocation: RoutePaths.registerVerify,
            companyId: null,
            status: null,
            companyIsActive: true,
          );
          expect(result, RoutePaths.login);
        },
      );
    });
  });
}
