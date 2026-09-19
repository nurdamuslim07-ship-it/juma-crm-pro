import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:http/http.dart' as http;
import 'package:juma_ui_crm/core/error/failures.dart';
import 'package:juma_ui_crm/core/providers/supabase_provider.dart';
import 'package:juma_ui_crm/features/auth/domain/entities/auth_user.dart';
import 'package:juma_ui_crm/features/auth/domain/entities/sign_up_outcome.dart';
import 'package:juma_ui_crm/features/auth/domain/repositories/auth_repository.dart';
import 'package:juma_ui_crm/features/auth/presentation/providers/auth_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;

/// Same hand-written-fake approach as sign_up_usecase_test.dart / this
/// module's other tests — no mocking framework exists in this codebase.
class _FakeAuthRepository implements AuthRepository {
  Failure? signUpFailure;
  Failure? signInFailure;
  Failure? resendFailure;
  Failure? sendOtpFailure;
  Failure? verifyOtpFailure;
  bool emailConfirmationRequired = false;

  int resendCount = 0;
  int sendOtpCount = 0;
  String? lastOtpPhoneSent;
  String? lastVerifiedPhone;
  String? lastVerifiedToken;
  String? lastSignInEmail;
  String? lastSignInPassword;

  @override
  Stream<AuthUser?> watchAuthState() => const Stream.empty();

  @override
  Future<Either<Failure, AuthUser>> signInWithPassword({
    required String email,
    required String password,
  }) async {
    lastSignInEmail = email;
    lastSignInPassword = password;
    if (signInFailure != null) return left(signInFailure!);
    return right(
      const AuthUser(
        id: 'user-1',
        fullName: 'Жаңа қолданушы',
        isActive: true,
        roleKeys: [],
      ),
    );
  }

  @override
  Future<Either<Failure, SignUpOutcome>> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phone,
  }) async {
    if (signUpFailure != null) return left(signUpFailure!);
    if (emailConfirmationRequired) {
      return right(const SignUpOutcome(emailConfirmationRequired: true));
    }
    return right(
      SignUpOutcome(
        emailConfirmationRequired: false,
        user: AuthUser(
          id: 'user-1',
          fullName: fullName,
          isActive: true,
          roleKeys: const [],
        ),
      ),
    );
  }

  @override
  Future<Either<Failure, Unit>> resendEmailConfirmation(String email) async {
    resendCount++;
    if (resendFailure != null) return left(resendFailure!);
    return right(unit);
  }

  @override
  Future<Either<Failure, Unit>> sendPhoneVerificationOtp(String phone) async {
    sendOtpCount++;
    lastOtpPhoneSent = phone;
    if (sendOtpFailure != null) return left(sendOtpFailure!);
    return right(unit);
  }

  @override
  Future<Either<Failure, AuthUser>> verifyPhoneOtp({
    required String phone,
    required String token,
  }) async {
    lastVerifiedPhone = phone;
    lastVerifiedToken = token;
    if (verifyOtpFailure != null) return left(verifyOtpFailure!);
    return right(
      const AuthUser(
        id: 'user-1',
        fullName: 'Жаңа қолданушы',
        isActive: true,
        roleKeys: [],
      ),
    );
  }

  @override
  Future<Either<Failure, Unit>> signOut() async => right(unit);

  @override
  Future<Either<Failure, Unit>> signOutAllDevices() async => right(unit);

  @override
  Future<Either<Failure, Unit>> sendPasswordResetEmail(String email) async =>
      right(unit);

  @override
  Future<Either<Failure, AuthUser?>> getCurrentUser() async => right(null);
}

/// Stands in for the real Supabase auth HTTP transport, same as
/// company_providers_test.dart's own copy — only understands the one
/// request `refreshVerificationState()`'s `auth.refreshSession()` call
/// issues.
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
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeAuthRepository repository;
  late _RecordingAuthHttpClient authHttpClient;
  late SupabaseClient supabaseClient;
  late ProviderContainer container;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    repository = _FakeAuthRepository();
    authHttpClient = _RecordingAuthHttpClient();
    supabaseClient = SupabaseClient(
      'https://test.supabase.co',
      'test-anon-key',
      httpClient: authHttpClient,
    );
    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(repository),
        supabaseClientProvider.overrideWithValue(supabaseClient),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(supabaseClient.dispose);
  });

  group('RegistrationController.register', () {
    test('session already exists (email confirmation disabled): saves pending '
        'registration state and returns no failure', () async {
      final failure = await container
          .read(registrationControllerProvider.notifier)
          .register(
            fullName: 'Жаңа қолданушы',
            email: 'new@juma.kz',
            phone: '+77010000000',
            password: 'password123',
          );

      expect(failure, isNull);
      final pending = container.read(pendingRegistrationProvider);
      expect(pending?.email, 'new@juma.kz');
      expect(pending?.phone, '+77010000000');
      expect(pending?.fullName, 'Жаңа қолданушы');
    });

    test('no session yet (email confirmation required): still saves pending '
        'registration state so it survives an app restart, and returns no '
        'failure — this is the exact case the old unconditional '
        '_loadProfile() call used to crash on', () async {
      repository.emailConfirmationRequired = true;
      final failure = await container
          .read(registrationControllerProvider.notifier)
          .register(
            fullName: 'Жаңа қолданушы',
            email: 'new@juma.kz',
            phone: '+77010000000',
            password: 'password123',
          );

      expect(failure, isNull);
      expect(container.read(pendingRegistrationProvider), isNotNull);
    });

    test('propagates a signUp failure without saving pending state', () async {
      repository.signUpFailure = const AuthFailure('Бұл email бұрын тіркелген');
      final failure = await container
          .read(registrationControllerProvider.notifier)
          .register(
            fullName: 'X',
            email: 'taken@juma.kz',
            phone: '+77010000000',
            password: 'password123',
          );

      expect(failure, isA<AuthFailure>());
      expect(container.read(pendingRegistrationProvider), isNull);
    });
  });

  group('RegistrationController.confirmEmailAndSignIn', () {
    test(
      'without a pending registration, fails instead of signing in blind',
      () async {
        final failure = await container
            .read(registrationControllerProvider.notifier)
            .confirmEmailAndSignIn('password123');
        expect(failure, isA<AuthFailure>());
        expect(repository.lastSignInEmail, isNull);
      },
    );

    test('signs in with the pending email and the given password', () async {
      await container
          .read(registrationControllerProvider.notifier)
          .register(
            fullName: 'Жаңа қолданушы',
            email: 'new@juma.kz',
            phone: '+77010000000',
            password: 'password123',
          );

      final failure = await container
          .read(registrationControllerProvider.notifier)
          .confirmEmailAndSignIn('password123');

      expect(failure, isNull);
      expect(repository.lastSignInEmail, 'new@juma.kz');
      expect(repository.lastSignInPassword, 'password123');
    });

    test('propagates Supabase\'s email_not_confirmed rejection when the link '
        'has not actually been clicked yet', () async {
      await container
          .read(registrationControllerProvider.notifier)
          .register(
            fullName: 'Жаңа қолданушы',
            email: 'new@juma.kz',
            phone: '+77010000000',
            password: 'password123',
          );
      repository.signInFailure = const AuthFailure(
        'Email әлі расталмаған. Хатты тексеріңіз',
      );

      final failure = await container
          .read(registrationControllerProvider.notifier)
          .confirmEmailAndSignIn('password123');

      expect(failure, isA<AuthFailure>());
    });
  });

  group('RegistrationController.resendEmailConfirmation', () {
    test('without a pending registration, fails instead of guessing', () async {
      final failure = await container
          .read(registrationControllerProvider.notifier)
          .resendEmailConfirmation();
      expect(failure, isA<AuthFailure>());
      expect(repository.resendCount, 0);
    });

    test('resends to the pending email', () async {
      await container
          .read(registrationControllerProvider.notifier)
          .register(
            fullName: 'X',
            email: 'new@juma.kz',
            phone: '+77010000000',
            password: 'password123',
          );

      final failure = await container
          .read(registrationControllerProvider.notifier)
          .resendEmailConfirmation();

      expect(failure, isNull);
      expect(repository.resendCount, 1);
    });
  });

  group('RegistrationController phone OTP', () {
    test('sendPhoneOtp forwards the exact phone given', () async {
      final failure = await container
          .read(registrationControllerProvider.notifier)
          .sendPhoneOtp('+77010000000');
      expect(failure, isNull);
      expect(repository.sendOtpCount, 1);
      expect(repository.lastOtpPhoneSent, '+77010000000');
    });

    test(
      'verifyPhoneOtp with the wrong/expired code surfaces the failure and '
      'keeps the pending registration state (so the user can retry)',
      () async {
        await container
            .read(registrationControllerProvider.notifier)
            .register(
              fullName: 'X',
              email: 'new@juma.kz',
              phone: '+77010000000',
              password: 'password123',
            );
        repository.verifyOtpFailure = const AuthFailure(
          'Код қате немесе мерзімі өтті. Қайта тексеріңіз',
        );

        final failure = await container
            .read(registrationControllerProvider.notifier)
            .verifyPhoneOtp(phone: '+77010000000', token: '000000');

        expect(failure, isA<AuthFailure>());
        expect(container.read(pendingRegistrationProvider), isNotNull);
      },
    );

    test('verifyPhoneOtp attaches the phone to the SAME already-authenticated '
        'user (never a second signInWithOtp/signUp) and clears pending state '
        'on success — registration is complete', () async {
      await container
          .read(registrationControllerProvider.notifier)
          .register(
            fullName: 'X',
            email: 'new@juma.kz',
            phone: '+77010000000',
            password: 'password123',
          );

      final failure = await container
          .read(registrationControllerProvider.notifier)
          .verifyPhoneOtp(phone: '+77010000000', token: '123456');

      expect(failure, isNull);
      expect(repository.lastVerifiedPhone, '+77010000000');
      expect(repository.lastVerifiedToken, '123456');
      expect(container.read(pendingRegistrationProvider), isNull);
    });
  });

  group('PendingRegistrationController persistence', () {
    test('save() then a fresh container restores it (simulates app restart, '
        'never the password)', () async {
      await container
          .read(pendingRegistrationProvider.notifier)
          .save(
            const PendingRegistration(
              fullName: 'Жаңа қолданушы',
              email: 'new@juma.kz',
              phone: '+77010000000',
            ),
          );

      final restartedContainer = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(repository),
          supabaseClientProvider.overrideWithValue(supabaseClient),
        ],
      );
      addTearDown(restartedContainer.dispose);
      // build() kicks off an async restore from SharedPreferences —
      // poll (bounded) instead of a fixed delay, since the mock
      // platform-channel round trip isn't guaranteed to resolve within
      // a single microtask/event-loop turn.
      PendingRegistration? restored;
      for (var i = 0; i < 50 && restored == null; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        restored = restartedContainer.read(pendingRegistrationProvider);
      }
      expect(restored?.email, 'new@juma.kz');
      expect(restored?.phone, '+77010000000');
      expect(restored?.fullName, 'Жаңа қолданушы');
    });

    test(
      'clear() removes it so a later restart has nothing to restore',
      () async {
        await container
            .read(pendingRegistrationProvider.notifier)
            .save(
              const PendingRegistration(
                fullName: 'X',
                email: 'new@juma.kz',
                phone: '+77010000000',
              ),
            );
        await container.read(pendingRegistrationProvider.notifier).clear();

        expect(container.read(pendingRegistrationProvider), isNull);

        final restartedContainer = ProviderContainer(
          overrides: [
            authRepositoryProvider.overrideWithValue(repository),
            supabaseClientProvider.overrideWithValue(supabaseClient),
          ],
        );
        addTearDown(restartedContainer.dispose);
        await pumpEventQueue();

        expect(restartedContainer.read(pendingRegistrationProvider), isNull);
      },
    );
  });

  group('RegistrationController.refreshVerificationState', () {
    test('forces a genuine onAuthStateChange via refreshSession()', () async {
      await supabaseClient.auth.recoverSession(
        jsonEncode({
          'access_token': 'test-access-token',
          'token_type': 'bearer',
          'refresh_token': 'test-refresh-token',
          'user': {'id': 'test-user-1', 'aud': 'authenticated'},
        }),
      );

      await container
          .read(registrationControllerProvider.notifier)
          .refreshVerificationState();

      expect(authHttpClient.refreshCallCount, 1);
    });
  });
}
