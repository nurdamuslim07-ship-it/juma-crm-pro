import 'package:flutter/foundation.dart';

import 'profile_status.dart';

/// Authenticated user + profile/role info — deliberately holds no
/// password field of any kind (contrast with the legacy web app's
/// `AppUser.password`, flagged as a critical finding in
/// SECURITY_PLAN.md). Password verification happens entirely inside
/// Supabase Auth; this entity is read-only profile/role data.
@immutable
class AuthUser {
  const AuthUser({
    required this.id,
    required this.fullName,
    this.email,
    this.phone,
    this.avatarUrl,
    required this.isActive,
    required this.roleKeys,
    this.companyId,
    this.status,
    this.companyIsActive = true,
    this.emailConfirmedAt,
    this.phoneConfirmedAt,
  });

  final String id;
  final String fullName;
  final String? email;
  final String? phone;
  final String? avatarUrl;

  /// Legacy "temporarily deactivated" toggle (`profiles.is_active`) —
  /// kept separate from [status] on purpose. It predates the
  /// multi-tenant conversion and is NOT the access gate anywhere
  /// server-side anymore (`auth_is_active()` reads `status`, not this
  /// column — see supabase/README.md's "Company registration" section,
  /// flagged there as a pre-existing gap out of that stage's scope).
  /// Never rename/reuse this field for membership state — that is what
  /// [status] and [isMember] are for.
  final bool isActive;

  /// e.g. ['director'], ['manager', 'measurer'] — see
  /// ROLES_AND_PERMISSIONS.md. UI-level convenience only; the real
  /// authorization boundary is Supabase RLS, not a check against this
  /// list (see SECURITY_PLAN.md finding #6).
  final List<String> roleKeys;

  /// `null` until the profile row is loaded, or the caller genuinely
  /// has no company yet (fresh signup, ahead of onboarding).
  final String? companyId;

  /// Onboarding/membership state (`profiles.status`) — `null` only in
  /// the same "not loaded yet" window as [companyId]. This, not
  /// [isActive], is what the router/RLS actually gate on.
  final ProfileStatus? status;

  /// The owning company's own `is_active` flag (defaults to `true`
  /// when there's no company yet, so a fresh signup isn't treated as
  /// "blocked"). Company-level equivalent of a suspended tenant — see
  /// supabase/README.md's "Company registration" section.
  final bool companyIsActive;

  /// Straight from Supabase Auth's `user.email_confirmed_at` — never
  /// set/derived by anything else in this app. `null` means "not
  /// confirmed" (or the project's "Confirm email" setting is off and
  /// never sets it at all — see RegistrationFlowController's own doc
  /// comment on why the registration flow requires that setting to be
  /// on for its email-verification step to mean anything).
  final DateTime? emailConfirmedAt;

  /// Straight from Supabase Auth's `user.phone_confirmed_at`, set only
  /// after `verifyOTP(type: OtpType.phoneChange, ...)` succeeds — see
  /// AuthRemoteDataSource.verifyPhoneOtp. Deliberately NOT sourced from
  /// or written to any `profiles` column: Supabase Auth is the sole
  /// source of truth for verification state (dual-contact registration
  /// spec's binding constraint).
  final DateTime? phoneConfirmedAt;

  bool hasRole(String key) => roleKeys.contains(key);
  bool get isDirector => hasRole('director') || hasRole('owner');
  bool get isOwner => hasRole('owner');

  /// True only once membership is genuinely active — the Flutter-side
  /// mirror of `auth_is_active()`. UI convenience only, same caveat as
  /// [roleKeys]: the real gate is server-side RLS.
  bool get isMember => status == ProfileStatus.active;

  bool get isEmailVerified => emailConfirmedAt != null;
  bool get isPhoneVerified => phoneConfirmedAt != null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthUser &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          fullName == other.fullName &&
          email == other.email &&
          phone == other.phone &&
          avatarUrl == other.avatarUrl &&
          isActive == other.isActive &&
          listEquals(roleKeys, other.roleKeys) &&
          companyId == other.companyId &&
          status == other.status &&
          companyIsActive == other.companyIsActive &&
          emailConfirmedAt == other.emailConfirmedAt &&
          phoneConfirmedAt == other.phoneConfirmedAt;

  @override
  int get hashCode => Object.hash(
    id,
    fullName,
    email,
    phone,
    avatarUrl,
    isActive,
    Object.hashAll(roleKeys),
    companyId,
    status,
    companyIsActive,
    emailConfirmedAt,
    phoneConfirmedAt,
  );
}
