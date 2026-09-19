import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/auth_user.dart';
import '../entities/sign_up_outcome.dart';

/// Domain-layer contract — the presentation layer only ever depends on
/// this interface, never on `data/datasources/auth_remote_datasource.dart`
/// or the Supabase SDK directly (see UI_ARCHITECTURE.md's layering rule).
abstract class AuthRepository {
  /// Emits the current profile whenever the Supabase auth session
  /// changes (sign in, sign out, token refresh), or `null` when signed
  /// out.
  Stream<AuthUser?> watchAuthState();

  /// Email + password only, by design — phone is never a login
  /// credential in this app, only a verified contact attached during
  /// registration (see AuthRemoteDataSource.signInWithPassword's own
  /// doc comment for why).
  Future<Either<Failure, AuthUser>> signInWithPassword({
    required String email,
    required String password,
  });

  /// Self-service registration — never passes a company id; the
  /// resulting profile starts with no company, `status = 'pending'`
  /// (see supabase/README.md's "Company registration" section). The
  /// caller picks create-vs-join afterwards via [CompanyRepository].
  /// See [SignUpOutcome] for why this can't just return an [AuthUser]
  /// directly — dual-contact registration also requires the caller to
  /// continue into the phone-verification step, which needs a session
  /// regardless of which outcome this returns.
  Future<Either<Failure, SignUpOutcome>> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phone,
  });

  /// Re-sends the "confirm your signup" email — see
  /// AuthRemoteDataSource.resendEmailConfirmation.
  Future<Either<Failure, Unit>> resendEmailConfirmation(String email);

  /// Attaches [phone] to the currently authenticated user and sends it
  /// an SMS OTP. Requires an existing session (post email confirmation)
  /// — see AuthRemoteDataSource.sendPhoneVerificationOtp for why this
  /// is never `signInWithOtp`.
  Future<Either<Failure, Unit>> sendPhoneVerificationOtp(String phone);

  /// Confirms the SMS code from [sendPhoneVerificationOtp], completing
  /// dual-contact verification for the current user.
  Future<Either<Failure, AuthUser>> verifyPhoneOtp({
    required String phone,
    required String token,
  });

  Future<Either<Failure, Unit>> signOut();

  /// Signs out every session for the current user, not just this
  /// device — see master spec: "Logout from all devices" /
  /// ROLES_AND_PERMISSIONS.md director capability "revoke sessions".
  Future<Either<Failure, Unit>> signOutAllDevices();

  Future<Either<Failure, Unit>> sendPasswordResetEmail(String email);

  Future<Either<Failure, AuthUser?>> getCurrentUser();
}
