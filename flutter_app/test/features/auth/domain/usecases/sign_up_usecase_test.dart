import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:juma_ui_crm/core/error/failures.dart';
import 'package:juma_ui_crm/features/auth/domain/entities/auth_user.dart';
import 'package:juma_ui_crm/features/auth/domain/entities/sign_up_outcome.dart';
import 'package:juma_ui_crm/features/auth/domain/repositories/auth_repository.dart';
import 'package:juma_ui_crm/features/auth/domain/usecases/sign_up_usecase.dart';

class _FakeAuthRepository implements AuthRepository {
  Failure? failureToReturn;
  bool emailConfirmationRequiredToReturn = false;
  String? lastEmail;
  String? lastFullName;
  String? lastPhone;

  @override
  Stream<AuthUser?> watchAuthState() => const Stream.empty();

  @override
  Future<Either<Failure, AuthUser>> signInWithPassword({
    required String email,
    required String password,
  }) async => left(const AuthFailure('not used in this test'));

  @override
  Future<Either<Failure, SignUpOutcome>> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phone,
  }) async {
    lastEmail = email;
    lastFullName = fullName;
    lastPhone = phone;
    if (failureToReturn != null) return left(failureToReturn!);
    if (emailConfirmationRequiredToReturn) {
      return right(const SignUpOutcome(emailConfirmationRequired: true));
    }
    return right(
      SignUpOutcome(
        emailConfirmationRequired: false,
        user: AuthUser(
          id: 'new-user',
          fullName: fullName,
          isActive: true,
          roleKeys: const [],
        ),
      ),
    );
  }

  @override
  Future<Either<Failure, Unit>> resendEmailConfirmation(String email) async =>
      right(unit);

  @override
  Future<Either<Failure, Unit>> sendPhoneVerificationOtp(String phone) async =>
      right(unit);

  @override
  Future<Either<Failure, AuthUser>> verifyPhoneOtp({
    required String phone,
    required String token,
  }) async => left(const AuthFailure('not used in this test'));

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

void main() {
  late _FakeAuthRepository repository;

  setUp(() {
    repository = _FakeAuthRepository();
  });

  test('signs up with no company id involved anywhere', () async {
    final useCase = SignUpUseCase(repository);
    final result = await useCase(
      email: 'new@juma.kz',
      password: 'password123',
      fullName: 'Жаңа қолданушы',
      phone: '+77010000000',
    );

    expect(repository.lastEmail, 'new@juma.kz');
    expect(repository.lastFullName, 'Жаңа қолданушы');
    expect(repository.lastPhone, '+77010000000');
    result.match((_) => fail('expected right'), (outcome) {
      expect(outcome.user?.companyId, isNull);
      expect(outcome.user?.status, isNull);
    });
  });

  test('propagates a signup failure (e.g. email already registered)', () async {
    repository.failureToReturn = const AuthFailure('Email тіркелген');
    final useCase = SignUpUseCase(repository);
    final result = await useCase(
      email: 'taken@juma.kz',
      password: 'password123',
      fullName: 'X',
      phone: '+77010000001',
    );
    expect(result.isLeft(), isTrue);
  });

  test('when Supabase requires email confirmation, the outcome carries no '
      'user — the caller must not try to load a profile with no session '
      '(this is the exact case the old unconditional _loadProfile call '
      'used to crash on)', () async {
    repository.emailConfirmationRequiredToReturn = true;
    final useCase = SignUpUseCase(repository);
    final result = await useCase(
      email: 'new@juma.kz',
      password: 'password123',
      fullName: 'Жаңа қолданушы',
      phone: '+77010000000',
    );

    result.match((_) => fail('expected right'), (outcome) {
      expect(outcome.emailConfirmationRequired, isTrue);
      expect(outcome.user, isNull);
    });
  });
}
