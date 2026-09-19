import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_paths.dart';
import '../providers/auth_providers.dart';
import 'email_confirmation_pending_screen.dart';
import 'phone_verification_screen.dart';

/// Single route (`RoutePaths.registerVerify`) for both remaining steps
/// of dual-contact registration — which one to render is derived live
/// from [currentUserProvider] (Supabase Auth's own confirmation
/// timestamps) and [pendingRegistrationProvider] (this device's
/// minimal, non-sensitive memory of an in-flight signup), never from a
/// separately tracked "current step" flag, so there is exactly one
/// source of truth for verification state and it can never drift from
/// what Supabase Auth actually thinks. See
/// core/router/onboarding_redirect.dart's `contactsVerified` gate for
/// what sends users here in the first place.
class RegistrationVerifyScreen extends ConsumerWidget {
  const RegistrationVerifyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final pending = ref.watch(pendingRegistrationProvider);

    if (user != null && !user.isEmailVerified) {
      return EmailConfirmationPendingScreen(
        email: user.email ?? pending?.email ?? '',
        needsPassword: false,
      );
    }
    if (user != null && !user.isPhoneVerified) {
      return PhoneVerificationScreen(phone: pending?.phone ?? user.phone ?? '');
    }
    if (user == null && pending != null) {
      return EmailConfirmationPendingScreen(
        email: pending.email,
        needsPassword: true,
      );
    }

    // Nothing pending and either no session or already fully verified
    // — the router redirect guard should never actually route here in
    // that case, but a stale deep link/back-navigation could still
    // land on this path directly.
    return _NothingPendingScreen(hasSession: user != null);
  }
}

class _NothingPendingScreen extends StatelessWidget {
  const _NothingPendingScreen({required this.hasSession});

  final bool hasSession;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: TextButton(
          onPressed: () => context.go(
            hasSession ? RoutePaths.onboarding : RoutePaths.register,
          ),
          child: const Icon(Icons.arrow_forward),
        ),
      ),
    );
  }
}
