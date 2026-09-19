import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/i18n/app_strings.dart';
import '../../domain/value_objects/employee_role.dart';

/// Kazakh label + icon per role — reuses the same 9(+2)-role set
/// already seeded in `roles` (see ROLES_AND_PERMISSIONS.md), so this
/// is presentation-only and never a second source of truth for what
/// roles exist.
extension EmployeeRolePresentation on EmployeeRole {
  String label(AppStrings s) {
    switch (this) {
      case EmployeeRole.director:
        return s.employeeRoleDirector;
      case EmployeeRole.manager:
        return s.employeeRoleManager;
      case EmployeeRole.measurer:
        return s.employeeRoleMeasurer;
      case EmployeeRole.designer:
        return s.employeeRoleDesigner;
      case EmployeeRole.workshopManager:
        return s.employeeRoleWorkshopManager;
      case EmployeeRole.master:
        return s.employeeRoleMaster;
      case EmployeeRole.assistant:
        return s.employeeRoleAssistant;
      case EmployeeRole.installer:
        return s.employeeRoleInstaller;
      case EmployeeRole.accountant:
        return s.employeeRoleAccountant;
      case EmployeeRole.warehouse:
        return s.employeeRoleWarehouse;
      case EmployeeRole.admin:
        return s.employeeRoleAdmin;
      case EmployeeRole.purchaser:
        return s.employeeRolePurchaser;
    }
  }

  IconData get icon {
    switch (this) {
      case EmployeeRole.director:
        return LucideIcons.crown;
      case EmployeeRole.manager:
        return LucideIcons.briefcase;
      case EmployeeRole.measurer:
        return LucideIcons.ruler;
      case EmployeeRole.designer:
        return LucideIcons.palette;
      case EmployeeRole.workshopManager:
        return LucideIcons.factory;
      case EmployeeRole.master:
        return LucideIcons.hammer;
      case EmployeeRole.assistant:
        return LucideIcons.userPlus;
      case EmployeeRole.installer:
        return LucideIcons.truck;
      case EmployeeRole.accountant:
        return LucideIcons.calculator;
      case EmployeeRole.warehouse:
        return LucideIcons.warehouse;
      case EmployeeRole.admin:
        return LucideIcons.shieldCheck;
      case EmployeeRole.purchaser:
        return LucideIcons.shoppingCart;
    }
  }
}
