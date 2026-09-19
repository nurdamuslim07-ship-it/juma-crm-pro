import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:juma_ui_crm/core/error/failures.dart';
import 'package:juma_ui_crm/features/auth/domain/entities/auth_user.dart';
import 'package:juma_ui_crm/features/auth/domain/entities/sign_up_outcome.dart';
import 'package:juma_ui_crm/features/auth/domain/repositories/auth_repository.dart';
import 'package:juma_ui_crm/features/auth/domain/usecases/sign_in_usecase.dart';

/// Same hand-written-fake approach as sign_up_usecase_test.dart — no
/// mocking framework exists in this codebase.
class _FakeAuthRepository implements AuthRepository {
  Failure? failureToReturn;
  String? lastEmail;
  String? lastPassword;

  @override
  Stream<AuthUser?> watchAuthState() => const Stream.empty();

  @override
  Future<Either<Failure, AuthUser>> signInWithPassword({
    required String email,
    required String password,
  }) async {
    lastEmail = email;
    lastPassword = password;
    if (failureToReturn != null) return left(failureToReturn!);
    return right(
      const AuthUser(id: 'user-1', fullName: 'X', isActive: true, roleKeys: []),
    );
  }

  @override
  Future<Either<Failure, SignUpOutcome>> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phone,
  }) async => left(const AuthFailure('not used in this test'));

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

  test('signs in with email + password only — the interface has no phone/OTP '
      'parameter at all, so a phone-based or passwordless sign-in call '
      'cannot be constructed through this use case', () async {
    final useCase = SignInUseCase(repository);
    final result = await useCase(
      email: 'director@juma.kz',
      password: 'password123',
    );

    expect(repository.lastEmail, 'director@juma.kz');
    expect(repository.lastPassword, 'password123');
    expect(result.isRight(), isTrue);
  });

  test('propagates a sign-in failure (e.g. wrong password)', () async {
    repository.failureToReturn = const AuthFailure(
      'Логин немесе құпиясөз қате',
    );
    final useCase = SignInUseCase(repository);
    final result = await useCase(email: 'director@juma.kz', password: 'wrong');
    expect(result.isLeft(), isTrue);
  });
}
