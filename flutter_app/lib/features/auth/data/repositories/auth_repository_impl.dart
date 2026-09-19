import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthApiException;

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/entities/sign_up_outcome.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._remote);
  final AuthRemoteDataSource _remote;

  @override
  Stream<AuthUser?> watchAuthState() => _remote.watchAuthState();

  @override
  Future<Either<Failure, AuthUser>> signInWithPassword({
    required String email,
    required String password,
  }) async {
    try {
      final user = await _remote.signInWithPassword(
        email: email,
        password: password,
      );
      return right(user);
    } on AuthException catch (e) {
      return left(AuthFailure(e.message));
    } on AuthApiException catch (e) {
      return left(AuthFailure(e.message));
    } catch (e) {
      return left(mapUnexpectedError(e));
    }
  }

  @override
  Future<Either<Failure, SignUpOutcome>> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phone,
  }) async {
    try {
      final user = await _remote.signUp(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
      );
      if (user == null) {
        return right(const SignUpOutcome(emailConfirmationRequired: true));
      }
      return right(SignUpOutcome(emailConfirmationRequired: false, user: user));
    } on AuthException catch (e) {
      return left(AuthFailure(e.message));
    } on AuthApiException catch (e) {
      return left(AuthFailure(e.message));
    } catch (e) {
      return left(mapUnexpectedError(e));
    }
  }

  @override
  Future<Either<Failure, Unit>> resendEmailConfirmation(String email) async {
    try {
      await _remote.resendEmailConfirmation(email);
      return right(unit);
    } on AuthException catch (e) {
      return left(AuthFailure(e.message));
    } on AuthApiException catch (e) {
      return left(AuthFailure(e.message));
    } catch (e) {
      return left(mapUnexpectedError(e));
    }
  }

  @override
  Future<Either<Failure, Unit>> sendPhoneVerificationOtp(String phone) async {
    try {
      await _remote.sendPhoneVerificationOtp(phone);
      return right(unit);
    } on AuthException catch (e) {
      return left(AuthFailure(e.message));
    } on AuthApiException catch (e) {
      return left(AuthFailure(e.message));
    } catch (e) {
      return left(mapUnexpectedError(e));
    }
  }

  @override
  Future<Either<Failure, AuthUser>> verifyPhoneOtp({
    required String phone,
    required String token,
  }) async {
    try {
      final user = await _remote.verifyPhoneOtp(phone: phone, token: token);
      return right(user);
    } on AuthException catch (e) {
      return left(AuthFailure(e.message));
    } on AuthApiException catch (e) {
      return left(AuthFailure(e.message));
    } catch (e) {
      return left(mapUnexpectedError(e));
    }
  }

  @override
  Future<Either<Failure, Unit>> signOut() async {
    try {
      await _remote.signOut();
      return right(unit);
    } catch (e) {
      return left(mapUnexpectedError(e));
    }
  }

  @override
  Future<Either<Failure, Unit>> signOutAllDevices() async {
    try {
      await _remote.signOut(allDevices: true);
      return right(unit);
    } catch (e) {
      return left(mapUnexpectedError(e));
    }
  }

  @override
  Future<Either<Failure, Unit>> sendPasswordResetEmail(String email) async {
    try {
      await _remote.sendPasswordResetEmail(email);
      return right(unit);
    } on AuthException catch (e) {
      return left(AuthFailure(e.message));
    } catch (e) {
      return left(mapUnexpectedError(e));
    }
  }

  @override
  Future<Either<Failure, AuthUser?>> getCurrentUser() async {
    try {
      final user = await _remote.getCurrentUser();
      return right(user);
    } catch (e) {
      return left(mapUnexpectedError(e));
    }
  }
}
