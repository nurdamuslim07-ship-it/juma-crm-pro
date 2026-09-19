import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/resend_email_confirmation_usecase.dart';
import '../../domain/usecases/send_password_reset_usecase.dart';
import '../../domain/usecases/send_phone_otp_usecase.dart';
import '../../domain/usecases/sign_in_usecase.dart';
import '../../domain/usecases/sign_out_usecase.dart';
import '../../domain/usecases/sign_up_usecase.dart';
import '../../domain/usecases/verify_phone_otp_usecase.dart';

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSource(ref.watch(supabaseClientProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(ref.watch(authRemoteDataSourceProvider));
});

final signInUseCaseProvider = Provider<SignInUseCase>((ref) {
  return SignInUseCase(ref.watch(authRepositoryProvider));
});

final signOutUseCaseProvider = Provider<SignOutUseCase>((ref) {
  return SignOutUseCase(ref.watch(authRepositoryProvider));
});

final sendPasswordResetUseCaseProvider = Provider<SendPasswordResetUseCase>((
  ref,
) {
  return SendPasswordResetUseCase(ref.watch(authRepositoryProvider));
});

final signUpUseCaseProvider = Provider<SignUpUseCase>((ref) {
  return SignUpUseCase(ref.watch(authRepositoryProvider));
});

final resendEmailConfirmationUseCaseProvider =
    Provider<ResendEmailConfirmationUseCase>((ref) {
      return ResendEmailConfirmationUseCase(ref.watch(authRepositoryProvider));
    });

final sendPhoneOtpUseCaseProvider = Provider<SendPhoneOtpUseCase>((ref) {
  return SendPhoneOtpUseCase(ref.watch(authRepositoryProvider));
});

final verifyPhoneOtpUseCaseProvider = Provider<VerifyPhoneOtpUseCase>((ref) {
  return VerifyPhoneOtpUseCase(ref.watch(authRepositoryProvider));
});

/// The single source of truth for "who is signed in" — the GoRouter
/// redirect guard, the profile menu, and every role-gated widget in
/// the app watch this instead of touching Supabase directly.
final authStateProvider = StreamProvider<AuthUser?>((ref) {
  return ref.watch(authRepositoryProvider).watchAuthState();
});

final currentUserProvider = Provider<AuthUser?>((ref) {
  return ref.watch(authStateProvider).valueOrNull;
});

/// Login-form submission state — kept separate from [authStateProvider]
/// so the login screen can show a loading spinner / inline error
/// without that state leaking into the rest of the app.
class LoginController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<Failure?> submit({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    final result = await ref
        .read(signInUseCaseProvider)
        .call(email: email, password: password);
    return result.match(
      (failure) {
        state = AsyncData(null);
        return failure;
      },
      (_) {
        state = const AsyncData(null);
        return null;
      },
    );
  }
}

final loginControllerProvider = AsyncNotifierProvider<LoginController, void>(
  LoginController.new,
);

/// Minimal, non-sensitive state carried across the dual-contact
/// registration flow so it survives an app restart between "signed up,
/// confirmation email sent" and "came back and clicked the link" —
/// deliberately holds no password/OTP, see [PendingRegistrationController].
class PendingRegistration {
  const PendingRegistration({
    required this.fullName,
    required this.email,
    required this.phone,
  });

  final String fullName;
  final String email;
  final String phone;
}

const _pendingRegFullNameKey = 'juma_ui_pending_reg_full_name';
const _pendingRegEmailKey = 'juma_ui_pending_reg_email';
const _pendingRegPhoneKey = 'juma_ui_pending_reg_phone';

/// Persists [PendingRegistration] the same direct-SharedPreferences way
/// [LocaleController] persists the chosen locale — see that class's own
/// doc comment for the convention this follows. Never stores the
/// password or any OTP: those live only in-memory in
/// [RegistrationController]'s call stack for the span of a single
/// request, per the dual-contact registration spec's binding
/// constraint ("never persist the plaintext password or OTP").
class PendingRegistrationController extends Notifier<PendingRegistration?> {
  @override
  PendingRegistration? build() {
    unawaited(_restore());
    return null;
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final fullName = prefs.getString(_pendingRegFullNameKey);
    final email = prefs.getString(_pendingRegEmailKey);
    final phone = prefs.getString(_pendingRegPhoneKey);
    if (fullName != null && email != null && phone != null) {
      state = PendingRegistration(
        fullName: fullName,
        email: email,
        phone: phone,
      );
    }
  }

  Future<void> save(PendingRegistration data) async {
    state = data;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pendingRegFullNameKey, data.fullName);
    await prefs.setString(_pendingRegEmailKey, data.email);
    await prefs.setString(_pendingRegPhoneKey, data.phone);
  }

  Future<void> clear() async {
    state = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingRegFullNameKey);
    await prefs.remove(_pendingRegEmailKey);
    await prefs.remove(_pendingRegPhoneKey);
  }
}

final pendingRegistrationProvider =
    NotifierProvider<PendingRegistrationController, PendingRegistration?>(
      PendingRegistrationController.new,
    );

/// Drives every step of the dual-contact registration flow after the
/// form itself (registration submit, resend-email, confirm-and-sign-in,
/// send/resend/verify phone OTP) — one controller because every step
/// but the first needs [pendingRegistrationProvider], and splitting
/// them would just mean every screen re-reading the same provider
/// pair. The actual "which screen to show" decision is NOT state on
/// this controller — it's derived live from [currentUserProvider] +
/// [pendingRegistrationProvider] by RegistrationVerifyScreen, so
/// Supabase Auth stays the single source of truth for verification
/// state rather than a second, potentially stale copy living here.
class RegistrationController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<Failure?> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) async {
    state = const AsyncLoading();
    final result = await ref
        .read(signUpUseCaseProvider)
        .call(
          email: email,
          password: password,
          fullName: fullName,
          phone: phone,
        );
    return result.match(
      (failure) {
        state = const AsyncData(null);
        return failure;
      },
      (outcome) async {
        // Whether a session exists yet (email confirmation disabled)
        // or not, PhoneVerificationScreen is what sends the first OTP,
        // the single time it first appears — not here — so an
        // already-confirmed restart and a fresh signup both send
        // exactly one OTP instead of risking a second, redundant send
        // the moment that screen mounts.
        await ref
            .read(pendingRegistrationProvider.notifier)
            .save(
              PendingRegistration(
                fullName: fullName,
                email: email,
                phone: phone,
              ),
            );
        state = const AsyncData(null);
        return null;
      },
    );
  }

  /// The pending-email screen's "Растадым, жалғастыру" action — signs
  /// in with the in-memory (never persisted) password to establish the
  /// session that email confirmation alone doesn't create on this
  /// device. Supabase itself rejects this with `email_not_confirmed`
  /// if the link hasn't actually been clicked yet, which is exactly
  /// the validation this step needs — no separate "check confirmed"
  /// call required.
  Future<Failure?> confirmEmailAndSignIn(String password) async {
    final pending = ref.read(pendingRegistrationProvider);
    if (pending == null) {
      return const AuthFailure('Тіркелу деректері табылмады. Қайта тіркеліңіз');
    }
    state = const AsyncLoading();
    final result = await ref
        .read(signInUseCaseProvider)
        .call(email: pending.email, password: password);
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

  Future<Failure?> resendEmailConfirmation() async {
    final pending = ref.read(pendingRegistrationProvider);
    if (pending == null) {
      return const AuthFailure('Тіркелу деректері табылмады. Қайта тіркеліңіз');
    }
    state = const AsyncLoading();
    final result = await ref
        .read(resendEmailConfirmationUseCaseProvider)
        .call(pending.email);
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

  /// Session already exists but `email_confirmed_at` may not have
  /// caught up locally yet — forces the same genuine
  /// `onAuthStateChange` refresh [CreateCompanyController]/
  /// `myMembershipRealtimeProvider` already rely on elsewhere, so
  /// [currentUserProvider] reloads with the latest confirmation state.
  Future<void> refreshVerificationState() async {
    await ref.read(supabaseClientProvider).auth.refreshSession();
  }

  Future<Failure?> sendPhoneOtp(String phone) async {
    state = const AsyncLoading();
    final result = await ref.read(sendPhoneOtpUseCaseProvider).call(phone);
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

  Future<Failure?> verifyPhoneOtp({
    required String phone,
    required String token,
  }) async {
    state = const AsyncLoading();
    final result = await ref
        .read(verifyPhoneOtpUseCaseProvider)
        .call(phone: phone, token: token);
    return result.match(
      (failure) {
        state = const AsyncData(null);
        return failure;
      },
      (_) async {
        await ref.read(pendingRegistrationProvider.notifier).clear();
        state = const AsyncData(null);
        return null;
      },
    );
  }
}

final registrationControllerProvider =
    AsyncNotifierProvider<RegistrationController, void>(
      RegistrationController.new,
    );
