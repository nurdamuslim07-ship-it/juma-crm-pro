import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/employee.dart';
import '../value_objects/employee_role.dart';
import '../value_objects/salary_type.dart';

abstract class EmployeeRepository {
  /// Routed entirely through `get_employees()` — see that RPC's doc
  /// comment in the migration for exactly which columns come back
  /// null depending on the caller's role. There is no client-side
  /// filtering step that could accidentally show more than the server
  /// sent.
  Future<Either<Failure, List<Employee>>> getEmployees({
    String? searchQuery,
    EmployeeRole? roleFilter,
    bool? activeFilter,
  });

  Future<Either<Failure, Employee>> getEmployee(String userId);

  /// Director-only — routed through the create-employee Edge Function,
  /// the only place a new Auth account is created (see
  /// supabase/functions/create-employee). Never touches the Postgres
  /// employees/user_roles tables directly from this client.
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
  });

  /// Director-only — routed through `update_employee()`, which also
  /// replaces the employee's role in `user_roles` (single-role
  /// semantics for this module — see that RPC's doc comment).
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
  });

  /// Requirement #5 "уақытша белсенді емес ету" — director-only,
  /// toggles `profiles.is_active` directly (already RLS-covered by
  /// the existing director-manage policy; independent of soft delete,
  /// per requirement).
  Future<Either<Failure, Unit>> setEmployeeActive(String userId, bool isActive);

  /// Requirement #6 — director-only, routed through
  /// `soft_delete_employee()`.
  Future<Either<Failure, Unit>> deleteEmployee(String userId);

  /// Any active user may call this for their OWN [userId] only — the
  /// `restrict_profile_self_update` trigger rejects anything except
  /// phone/avatar_url regardless of what this sends, and RLS rejects
  /// targeting anyone else's row.
  Future<Either<Failure, Unit>> updateOwnContactInfo({
    String? phone,
    String? avatarUrl,
  });

  Future<Either<Failure, String>> uploadAvatar({
    required String userId,
    required List<int> bytes,
    required String fileName,
  });
}
