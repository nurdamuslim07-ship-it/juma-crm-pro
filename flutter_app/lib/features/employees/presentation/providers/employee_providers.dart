import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/supabase_provider.dart';
import '../../../../core/realtime/table_realtime_provider.dart';
import '../../data/datasources/employee_remote_datasource.dart';
import '../../data/repositories/employee_repository_impl.dart';
import '../../domain/entities/employee.dart';
import '../../domain/repositories/employee_repository.dart';
import '../../domain/usecases/create_employee_usecase.dart';
import '../../domain/usecases/delete_employee_usecase.dart';
import '../../domain/usecases/get_employees_usecase.dart';
import '../../domain/usecases/set_employee_active_usecase.dart';
import '../../domain/usecases/update_employee_usecase.dart';
import '../../domain/usecases/update_own_contact_info_usecase.dart';
import '../../domain/usecases/upload_avatar_usecase.dart';
import '../../domain/value_objects/employee_role.dart';

final employeeRemoteDataSourceProvider = Provider<EmployeeRemoteDataSource>((
  ref,
) {
  return EmployeeRemoteDataSource(ref.watch(supabaseClientProvider));
});

final employeeRepositoryProvider = Provider<EmployeeRepository>((ref) {
  return EmployeeRepositoryImpl(ref.watch(employeeRemoteDataSourceProvider));
});

final getEmployeesUseCaseProvider = Provider<GetEmployeesUseCase>((ref) {
  return GetEmployeesUseCase(ref.watch(employeeRepositoryProvider));
});

final createEmployeeUseCaseProvider = Provider<CreateEmployeeUseCase>((ref) {
  return CreateEmployeeUseCase(ref.watch(employeeRepositoryProvider));
});

final updateEmployeeUseCaseProvider = Provider<UpdateEmployeeUseCase>((ref) {
  return UpdateEmployeeUseCase(ref.watch(employeeRepositoryProvider));
});

final setEmployeeActiveUseCaseProvider = Provider<SetEmployeeActiveUseCase>((
  ref,
) {
  return SetEmployeeActiveUseCase(ref.watch(employeeRepositoryProvider));
});

final deleteEmployeeUseCaseProvider = Provider<DeleteEmployeeUseCase>((ref) {
  return DeleteEmployeeUseCase(ref.watch(employeeRepositoryProvider));
});

final updateOwnContactInfoUseCaseProvider =
    Provider<UpdateOwnContactInfoUseCase>((ref) {
      return UpdateOwnContactInfoUseCase(ref.watch(employeeRepositoryProvider));
    });

final uploadAvatarUseCaseProvider = Provider<UploadAvatarUseCase>((ref) {
  return UploadAvatarUseCase(ref.watch(employeeRepositoryProvider));
});

final employeeSearchQueryProvider = StateProvider<String>((ref) => '');
final employeeRoleFilterProvider = StateProvider<EmployeeRole?>((ref) => null);

/// `null` = "барлық статустар" (both active and inactive).
final employeeActiveFilterProvider = StateProvider<bool?>((ref) => null);

final employeesListProvider = FutureProvider.autoDispose<List<Employee>>((ref) {
  final query = ref.watch(employeeSearchQueryProvider);
  final role = ref.watch(employeeRoleFilterProvider);
  final active = ref.watch(employeeActiveFilterProvider);
  return ref
      .watch(getEmployeesUseCaseProvider)
      .call(searchQuery: query, roleFilter: role, activeFilter: active)
      .then(
        (either) => either.match((failure) => throw failure, (data) => data),
      );
});

final employeeDetailProvider = FutureProvider.autoDispose
    .family<Employee, String>((ref, userId) {
      return ref
          .watch(employeeRepositoryProvider)
          .getEmployee(userId)
          .then(
            (either) =>
                either.match((failure) => throw failure, (data) => data),
          );
    });

/// Stage 4 Part 1 — `employees` has all direct grants revoked (RPC-
/// only access, see that module's own header comment), so Realtime
/// (which is gated by the same RLS/grants as a normal query) can never
/// deliver events for it directly. `profiles` is the proxy: every
/// employee-affecting action (create/update/role-change/soft-delete,
/// and company-membership changes from Stage 1e/2/3) also touches a
/// `profiles` row, and that table has a real, non-revoked SELECT
/// policy. This same subscription is what "Company Members" realtime
/// (CompanyMembersScreen reuses `employeesListProvider`) rides on too.
final employeesRealtimeProvider = tableRealtimeProvider('profiles', (ref) {
  ref.invalidate(employeesListProvider);
});
