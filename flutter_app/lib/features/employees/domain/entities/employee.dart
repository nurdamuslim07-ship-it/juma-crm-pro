import 'package:flutter/foundation.dart';

import '../value_objects/employee_role.dart';
import '../value_objects/salary_type.dart';

/// See supabase/migrations/20260713000017_employees_module.sql. Every
/// instance of this class comes from `get_employees()`, never a raw
/// table select — [salaryType]/[baseSalaryTiyn]/[bonusPercent] being
/// `null` is not "no value set", it means the RPC redacted them
/// because the caller isn't the director ([hasFinancialAccess]
/// distinguishes the two — see that getter's doc comment).
@immutable
class Employee {
  const Employee({
    required this.id,
    required this.userId,
    required this.fullName,
    this.phone,
    required this.email,
    this.avatarUrl,
    required this.isActive,
    this.hireDate,
    this.salaryType,
    this.baseSalaryTiyn,
    this.bonusPercent,
    this.notes,
    this.role,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String fullName;
  final String? phone;
  final String email;
  final String? avatarUrl;
  final bool isActive;
  final DateTime? hireDate;
  final SalaryType? salaryType;
  final int? baseSalaryTiyn;
  final double? bonusPercent;
  final String? notes;
  final EmployeeRole? role;
  final DateTime createdAt;

  /// `true` only when the server actually sent salary/bonus data —
  /// i.e. the caller holds `employees.read_financial` (director). A
  /// `false` here must never be rendered as "0 ₸" — see
  /// EmployeeDetailScreen, which shows a "жасырын" placeholder
  /// instead whenever this is false, so a hidden field can never be
  /// mistaken for a genuinely zero salary.
  bool get hasFinancialAccess => salaryType != null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Employee &&
          runtimeType == other.runtimeType &&
          userId == other.userId;

  @override
  int get hashCode => userId.hashCode;
}
