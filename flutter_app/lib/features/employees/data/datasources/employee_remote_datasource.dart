import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/exceptions.dart';
import '../../domain/value_objects/employee_role.dart';
import '../../domain/value_objects/salary_type.dart';
import '../models/employee_model.dart';

/// See supabase/migrations/20260713000017_employees_module.sql. Every
/// read/write here goes through an RPC or the create-employee Edge
/// Function — this class never issues a raw `.from('employees')`
/// query, because the base table has no grants for `authenticated` at
/// all (see that migration's header comment).
class EmployeeRemoteDataSource {
  EmployeeRemoteDataSource(this._client);
  final SupabaseClient _client;

  Future<List<EmployeeModel>> getEmployees({
    String? searchQuery,
    EmployeeRole? roleFilter,
    bool? activeFilter,
  }) async {
    final rows = await _client.rpc(
      'get_employees',
      params: {
        'p_search': (searchQuery == null || searchQuery.trim().isEmpty)
            ? null
            : searchQuery.trim(),
        'p_role_filter': roleFilter?.dbKey,
        'p_active_filter': activeFilter,
      },
    );
    return (rows as List)
        .map((row) => EmployeeModel.fromRow(row as Map<String, dynamic>))
        .toList();
  }

  Future<EmployeeModel> getEmployee(String userId) async {
    final rows = await _client.rpc(
      'get_employees',
      params: {'p_user_id': userId},
    );
    final list = rows as List;
    if (list.isEmpty) {
      throw const NotFoundException('Қызметкер табылмады');
    }
    return EmployeeModel.fromRow(list.first as Map<String, dynamic>);
  }

  /// Invokes the create-employee Edge Function — see
  /// supabase/functions/create-employee/index.ts. The service role
  /// key that function needs lives only in its own server-side
  /// environment; this call carries only the caller's normal session.
  Future<String> createEmployee({
    required String email,
    required String password,
    required String fullName,
    String? phone,
    required EmployeeRole role,
    DateTime? hireDate,
    required SalaryType salaryType,
    required int baseSalaryTiyn,
    required double bonusPercent,
    String? notes,
  }) async {
    final response = await _client.functions.invoke(
      'create-employee',
      body: {
        'email': email,
        'password': password,
        'fullName': fullName,
        'phone': phone,
        'roleKey': role.dbKey,
        'hireDate': hireDate?.toIso8601String().substring(0, 10),
        'salaryType': salaryType.dbKey,
        'baseSalaryTiyn': baseSalaryTiyn,
        'bonusPercent': bonusPercent,
        'notes': notes,
      },
    );

    final data = response.data;
    if (response.status != 200 || data is! Map || data['userId'] == null) {
      final message =
          (data is Map ? data['error'] as String? : null) ??
          'Қызметкер жасалмады';
      throw ServerException(message);
    }
    return data['userId'] as String;
  }

  Future<void> updateEmployee({
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
      await _client.rpc(
        'update_employee',
        params: {
          'p_user_id': userId,
          'p_full_name': fullName,
          'p_phone': phone,
          'p_role_key': role.dbKey,
          'p_hire_date': hireDate?.toIso8601String().substring(0, 10),
          'p_salary_type': salaryType.dbKey,
          'p_base_salary_tiyn': baseSalaryTiyn,
          'p_bonus_percent': bonusPercent,
          'p_notes': notes,
        },
      );
    } on PostgrestException catch (e) {
      if (e.code == '42501') throw ServerException(e.message);
      rethrow;
    }
  }

  Future<void> setEmployeeActive(String userId, bool isActive) async {
    try {
      await _client
          .from('profiles')
          .update({'is_active': isActive})
          .eq('id', userId);
    } on PostgrestException catch (e) {
      if (e.code == '42501') throw ServerException(e.message);
      rethrow;
    }
  }

  Future<void> deleteEmployee(String userId) async {
    try {
      await _client.rpc('soft_delete_employee', params: {'p_user_id': userId});
    } on PostgrestException catch (e) {
      if (e.code == '42501') throw ServerException(e.message);
      rethrow;
    }
  }

  Future<void> updateOwnContactInfo({String? phone, String? avatarUrl}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw const ServerException('Сессия табылмады');

    final fields = <String, dynamic>{};
    if (phone != null) fields['phone'] = phone;
    if (avatarUrl != null) fields['avatar_url'] = avatarUrl;
    if (fields.isEmpty) return;

    try {
      await _client.from('profiles').update(fields).eq('id', userId);
    } on PostgrestException catch (e) {
      if (e.code == '42501') throw ServerException(e.message);
      rethrow;
    }
  }

  Future<String> uploadAvatar({
    required String userId,
    required List<int> bytes,
    required String fileName,
  }) async {
    final path = '$userId/${DateTime.now().millisecondsSinceEpoch}-$fileName';
    await _client.storage
        .from('avatars')
        .uploadBinary(
          path,
          Uint8List.fromList(bytes),
          fileOptions: const FileOptions(upsert: true),
        );
    return _client.storage.from('avatars').getPublicUrl(path);
  }
}
