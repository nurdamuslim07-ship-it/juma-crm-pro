import 'package:flutter/foundation.dart';

import 'auth_user.dart';

/// Result of [AuthRepository.signUp] — Supabase Auth can respond to
/// `signUp()` two different ways depending on the project's "Confirm
/// email" setting (see SECURITY_PLAN.md-style config notes in
/// AuthRemoteDataSource.signUp's own doc comment): a session is
/// returned immediately, or only a user with no session while a
/// confirmation email is sent. The old code silently assumed the
/// former and crashed loading a profile with no session to read it
/// under RLS — this type makes the caller handle both on purpose.
@immutable
class SignUpOutcome {
  const SignUpOutcome({required this.emailConfirmationRequired, this.user});

  final bool emailConfirmationRequired;

  /// Non-null only when `emailConfirmationRequired` is false — a
  /// session (and therefore a loadable profile) already exists.
  final AuthUser? user;
}
