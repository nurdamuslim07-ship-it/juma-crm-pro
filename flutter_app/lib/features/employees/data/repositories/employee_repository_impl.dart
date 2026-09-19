import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show FunctionException, PostgrestException, StorageException;

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/employee.dart';
import '../../domain/repositories/employee_repository.dart';
import '../../domain/value_objects/employee_role.dart';
import '../../domain/value_objects/salary_type.dart';
import '../datasources/employee_remote_datasource.dart';

class EmployeeRepositoryImpl implements EmployeeRepository {
  EmployeeRepositoryImpl(this._remote);
  final EmployeeRemoteDataSource _remote;

  @override
  Future<Either<Failure, List<Employee>>> getEmployees({
    String? searchQuery,
    EmployeeRole? roleFilter,
    bool? activeFilter,
  }) async {
    try {
      final employees = await _remote.getEmployees(
        searchQuery: searchQuery,
        roleFilter: roleFilter,
        activeFilter: activeFilter,
      );
      return right(employees);
    } on PostgrestException catch (e) {
      return left(_mapPostgrestError(e));
    } catch (e) {
      return left(mapUnexpectedError(e));
    }
  }

  @override
  Future<Either<Failure, Employee>> getEmployee(String userId) async {
    try {
      final employee = await _remote.getEmployee(userId);
      return right(employee);
    } on NotFoundException catch (e) {
      return left(NotFoundFailure(e.message ?? 'Қызметкер табылмады'));
    } on PostgrestException catch (e) {
      return left(_mapPostgrestError(e));
    } catch (e) {
      return left(mapUnexpectedError(e));
    }
  }

  @override
  Future<Either<Failure, String>> createEmployee({
    required String email,
    required String password,
    required String fullName,
    String? phone,
    required EmployeeRole role,
    DateTime? hireDate,
    SalaryType salaryType = SalaryType.fixed,
    int baseSalaryTiyn = 0,
    double bonusPercent = 0,
    String? notes,
  }) async {
    try {
      final userId = await _remote.createEmployee(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
        role: role,
        hireDate: hireDate,
        salaryType: salaryType,
        baseSalaryTiyn: baseSalaryTiyn,
        bonusPercent: bonusPercent,
        notes: notes,
      );
      return right(userId);
    } on ServerException catch (e) {
      return left(ValidationFailure(e.message ?? 'Қызметкер жасалмады'));
    } on FunctionException catch (e) {
      return left(
        ServerFailure(e.details?.toString() ?? 'Edge Function қатесі'),
      );
    } catch (e) {
      return left(mapUnexpectedError(e));
    }
  }

  @override
  Future<Either<Failure, Unit>> updateEmployee({
    required String userId,
    required String fullName,
    String? phone,
    required EmployeeRole role,
    DateTime? hireDate,
    required SalaryType salaryType,
    required int baseSalaryTiyn,
    required double bonusPercent,
    String? notes,
  }) async {
    try {
      await _remote.updateEmployee(
        userId: userId,
        fullName: fullName,
        phone: phone,
        role: role,
        hireDate: hireDate,
        salaryType: salaryType,
        baseSalaryTiyn: baseSalaryTiyn,
        bonusPercent: bonusPercent,
        notes: notes,
      );
      return right(unit);
    } on ServerException catch (e) {
      return left(
        e.message == null
            ? const PermissionFailure()
            : PermissionFailure(e.message!),
      );
    } on PostgrestException catch (e) {
      return left(_mapPostgrestError(e));
    } catch (e) {
      return left(mapUnexpectedError(e));
    }
  }

  @override
  Future<Either<Failure, Unit>> setEmployeeActive(
    String userId,
    bool isActive,
  ) async {
    try {
      await _remote.setEmployeeActive(userId, isActive);
      return right(unit);
    } on ServerException catch (e) {
      return left(
        e.message == null
            ? const PermissionFailure()
            : PermissionFailure(e.message!),
      );
    } on PostgrestException catch (e) {
      return left(_mapPostgrestError(e));
    } catch (e) {
      return left(mapUnexpectedError(e));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteEmployee(String userId) async {
    try {
      await _remote.deleteEmployee(userId);
      return right(unit);
    } on ServerException catch (e) {
      return left(
        e.message == null
            ? const PermissionFailure()
            : PermissionFailure(e.message!),
      );
    } on PostgrestException catch (e) {
      return left(_mapPostgrestError(e));
    } catch (e) {
      return left(mapUnexpectedError(e));
    }
  }

  @override
  Future<Either<Failure, Unit>> updateOwnContactInfo({
    String? phone,
    String? avatarUrl,
  }) async {
    try {
      await _remote.updateOwnContactInfo(phone: phone, avatarUrl: avatarUrl);
      return right(unit);
    } on ServerException catch (e) {
      return left(
        e.message == null
            ? const PermissionFailure()
            : PermissionFailure(e.message!),
      );
    } on PostgrestException catch (e) {
      return left(_mapPostgrestError(e));
    } catch (e) {
      return left(mapUnexpectedError(e));
    }
  }

  @override
  Future<Either<Failure, String>> uploadAvatar({
    required String userId,
    required List<int> bytes,
    required String fileName,
  }) async {
    try {
      final url = await _remote.uploadAvatar(
        userId: userId,
        bytes: bytes,
        fileName: fileName,
      );
      return right(url);
    } on StorageException catch (e) {
      return left(ServerFailure(e.message));
    } catch (e) {
      return left(mapUnexpectedError(e));
    }
  }

  Failure _mapPostgrestError(PostgrestException e) {
    if (e.code == '42501') return PermissionFailure(e.message);
    if (e.code == 'PGRST116') return const NotFoundFailure();
    return ServerFailure(e.message);
  }
}
