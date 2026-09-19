import 'package:flutter/foundation.dart';

/// Minimal `profiles` projection for the "Жауапты қызметкер"
/// (responsible employee) picker on the order form. Deliberately not
/// the richer Employee entity the future Employees module will define
/// (roles, active tasks, bonuses, etc.) — this is only what a picker
/// list needs, sourced directly from `profiles` since no Employees
/// feature exists yet to depend on.
@immutable
class EmployeeOption {
  const EmployeeOption({required this.id, required this.fullName, this.phone});

  final String id;
  final String fullName;
  final String? phone;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmployeeOption &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
