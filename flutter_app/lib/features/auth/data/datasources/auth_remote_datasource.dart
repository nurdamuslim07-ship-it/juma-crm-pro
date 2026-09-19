import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/exceptions.dart' as app_exceptions;
import '../models/auth_user_model.dart';

/// Talks to Supabase Auth + the `profiles`/`user_roles`/`roles` tables
/// directly. This is the ONLY file in the app allowed to call
/// `supabase.auth.*` — everything above (repository, usecases,
/// presentation) goes through the domain `AuthRepository` interface
/// instead (see UI_ARCHITECTURE.md's target `services/`/`data/` split,
/// replacing the legacy web app's ad hoc `src/lib/firebase.ts` helpers
/// called directly from `App.tsx`).
class AuthRemoteDataSource {
  AuthRemoteDataSource(this._client);
  final SupabaseClient _client;

  Stream<AuthUserModel?> watchAuthState() {
    return _client.auth.onAuthStateChange.asyncMap((event) async {
      final user = event.session?.user;
      if (user == null) return null;
      return _loadProfile(user);
    });
  }

  /// Self-service registration — `handle_new_auth_user()` creates the
  /// `profiles` row server-side (company_id null, status 'pending')
  /// the moment `auth.users` gets this new row; nothing here ever
  /// passes a company_id (see supabase/README.md's "Company
  /// registration" section — that is what create_company_and_owner()/
  /// request_to_join_company() are for, called separately once
  /// signed in). [phone] is only ever passed as `raw_user_meta_data` —
  /// a prefill for `profiles.phone`, not a verified contact; the real
  /// verified attach happens later via [sendPhoneVerificationOtp] +
  /// [verifyPhoneOtp] against this SAME user, once signed in.
  ///
  /// Returns `null` when the project's "Confirm email" setting means
  /// Supabase issued no session yet (only sent a confirmation email) —
  /// there is then no session for RLS to allow `_loadProfile` to read
  /// under, and the caller must not attempt it. This was previously an
  /// unconditional `_loadProfile(user)` call that crashed in exactly
  /// this case.
  Future<AuthUserModel?> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phone,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName, 'phone': phone},
      );
      final user = response.user;
      if (user == null) {
        throw const app_exceptions.AuthException('Тіркелу сәтсіз аяқталды');
      }
      if (response.session == null) return null;
      return _loadProfile(user);
    } on AuthApiException catch (e) {
      throw app_exceptions.AuthException(_mapAuthError(e));
    }
  }

  /// Re-sends the "confirm your signup" email — used by the pending-
  /// confirmation screen's resend action.
  Future<void> resendEmailConfirmation(String email) async {
    try {
      await _client.auth.resend(type: OtpType.signup, email: email);
    } on AuthApiException catch (e) {
      throw app_exceptions.AuthException(_mapAuthError(e));
    }
  }

  /// Attaches [phone] to the CURRENTLY authenticated user (requires an
  /// existing session — email must already be confirmed/signed in) and
  /// sends it an SMS OTP. Deliberately `updateUser`, never
  /// `signInWithOtp` or a second `signUp` — either of those would
  /// create or authenticate a *different* auth user keyed by phone,
  /// defeating the entire point of "one user, two verified contacts".
  /// Supabase does not set `auth.users.phone`/`phone_confirmed_at`
  /// until [verifyPhoneOtp] succeeds.
  Future<void> sendPhoneVerificationOtp(String phone) async {
    try {
      await _client.auth.updateUser(UserAttributes(phone: phone));
    } on AuthApiException catch (e) {
      throw app_exceptions.AuthException(_mapAuthError(e));
    }
  }

  /// Confirms the SMS code sent by [sendPhoneVerificationOtp]. Uses
  /// `OtpType.phoneChange` specifically — the verification type for a
  /// phone attached via `updateUser`, distinct from `OtpType.sms`
  /// (phone sign-in), which the caller must never use here.
  Future<AuthUserModel> verifyPhoneOtp({
    required String phone,
    required String token,
  }) async {
    try {
      final response = await _client.auth.verifyOTP(
        type: OtpType.phoneChange,
        phone: phone,
        token: token,
      );
      final user = response.user ?? _client.auth.currentUser;
      if (user == null) {
        throw const app_exceptions.AuthException('Растау сәтсіз аяқталды');
      }
      return _loadProfile(user);
    } on AuthApiException catch (e) {
      throw app_exceptions.AuthException(_mapAuthError(e));
    }
  }

  /// Email + password only — deliberately never `phone:`. Attaching a
  /// verified phone via [sendPhoneVerificationOtp]/[verifyPhoneOtp]
  /// during registration sets `auth.users.phone`, which would silently
  /// make Supabase's own `signInWithPassword(phone: ...)` start working
  /// the moment a phone is verified if this branched on identifier
  /// shape the way it used to. Email+password stays the only primary
  /// sign-in method — phone is a verified contact, never a login
  /// credential (binding constraint, not a suggestion).
  Future<AuthUserModel> signInWithPassword({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final user = response.user;
      if (user == null) {
        throw const app_exceptions.AuthException('Логин немесе құпиясөз қате');
      }
      return _loadProfile(user);
    } on AuthApiException catch (e) {
      throw app_exceptions.AuthException(_mapAuthError(e));
    }
  }

  Future<void> signOut({bool allDevices = false}) async {
    await _client.auth.signOut(
      scope: allDevices ? SignOutScope.global : SignOutScope.local,
    );
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
    } on AuthApiException catch (e) {
      throw app_exceptions.AuthException(_mapAuthError(e));
    }
  }

  Future<AuthUserModel?> getCurrentUser() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    return _loadProfile(user);
  }

  Future<AuthUserModel> _loadProfile(User user) async {
    // `companies(is_active)` is a PostgREST foreign-table embed via the
    // profiles.company_id -> companies.id FK — safe under RLS since a
    // profile only ever embeds its OWN company (companies_select_own
    // is `id = auth_company_id()`, and this row's company_id IS
    // auth_company_id() for its own owner).
    final profileRow = await _client
        .from('profiles')
        .select('*, companies(is_active)')
        .eq('id', user.id)
        .single();

    final roleRows = await _client
        .from('user_roles')
        .select('roles(key)')
        .eq('profile_id', user.id);

    final roleKeys = (roleRows as List)
        .map((row) => (row['roles'] as Map<String, dynamic>)['key'] as String)
        .toList();

    return AuthUserModel.fromProfileRow(
      profileRow,
      roleKeys: roleKeys,
      email: user.email,
      emailConfirmedAt: user.emailConfirmedAt,
      phoneConfirmedAt: user.phoneConfirmedAt,
    );
  }

  String _mapAuthError(AuthApiException e) {
    // Checked first: precise, code-based cases the generic status-code
    // switch below can't distinguish (e.g. a 422/403 covers several
    // very different situations). See
    // https://supabase.com/docs/guides/auth/debugging/error-codes —
    // full list in the `gotrue` package's `ErrorCode` enum.
    switch (e.code) {
      case 'email_exists':
        return 'Бұл email бұрын тіркелген';
      case 'phone_exists':
        return 'Бұл телефон нөмірі бұрын тіркелген';
      case 'otp_expired':
        return 'Код қате немесе мерзімі өтті. Қайта тексеріңіз';
      case 'over_email_send_rate_limit':
      case 'over_sms_send_rate_limit':
      case 'over_request_rate_limit':
        return 'Тым көп әрекет. Сәл кейін қайталаңыз';
      case 'sms_send_failed':
        return 'SMS жіберілмеді. Кейінірек қайталаңыз';
      case 'email_not_confirmed':
        return 'Email әлі расталмаған. Хатты тексеріңіз';
      case 'phone_not_confirmed':
        return 'Телефон әлі расталмаған';
      case 'weak_password':
        return 'Құпиясөз тым әлсіз';
      case 'email_provider_disabled':
      case 'phone_provider_disabled':
        return 'Бұл тіркелу әдісі қазір өшірулі. Әкімшіге хабарласыңыз';
    }
    switch (e.statusCode) {
      case '400':
      case '401':
        return 'Логин немесе құпиясөз қате';
      case '429':
        return 'Тым көп әрекет. Сәл кейін қайталаңыз';
      default:
        return e.message;
    }
  }
}
