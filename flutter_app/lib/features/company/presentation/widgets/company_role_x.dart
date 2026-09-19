import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/i18n/app_strings.dart';
import '../../domain/value_objects/company_role.dart';

/// Kazakh/Russian label + icon per role. Reuses the same
/// `employeeRole*` strings the Employees module already has for every
/// role [CompanyRole] shares with `EmployeeRole` (both mirror the same
/// `role_key` enum) — `viewer` is the one value only this module's
/// role set has, so it gets its own `companyRoleViewer` string (see
/// core/i18n/app_strings.dart). This is presentation-only and never a
/// second source of truth for what roles exist.
extension CompanyRolePresentation on CompanyRole {
  String label(AppStrings s) {
    switch (this) {
      case CompanyRole.director:
        return s.employeeRoleDirector;
      case CompanyRole.manager:
        return s.employeeRoleManager;
      case CompanyRole.measurer:
        return s.employeeRoleMeasurer;
      case CompanyRole.designer:
        return s.employeeRoleDesigner;
      case CompanyRole.workshopManager:
        return s.employeeRoleWorkshopManager;
      case CompanyRole.master:
        return s.employeeRoleMaster;
      case CompanyRole.assistant:
        return s.employeeRoleAssistant;
      case CompanyRole.installer:
        return s.employeeRoleInstaller;
      case CompanyRole.accountant:
        return s.employeeRoleAccountant;
      case CompanyRole.warehouse:
        return s.employeeRoleWarehouse;
      case CompanyRole.admin:
        return s.employeeRoleAdmin;
      case CompanyRole.purchaser:
        return s.employeeRolePurchaser;
      case CompanyRole.viewer:
        return s.companyRoleViewer;
    }
  }

  IconData get icon {
    switch (this) {
      case CompanyRole.director:
        return LucideIcons.crown;
      case CompanyRole.manager:
        return LucideIcons.briefcase;
      case CompanyRole.measurer:
        return LucideIcons.ruler;
      case CompanyRole.designer:
        return LucideIcons.palette;
      case CompanyRole.workshopManager:
        return LucideIcons.factory;
      case CompanyRole.master:
        return LucideIcons.hammer;
      case CompanyRole.assistant:
        return LucideIcons.userPlus;
      case CompanyRole.installer:
        return LucideIcons.truck;
      case CompanyRole.accountant:
        return LucideIcons.calculator;
      case CompanyRole.warehouse:
        return LucideIcons.warehouse;
      case CompanyRole.admin:
        return LucideIcons.shieldCheck;
      case CompanyRole.purchaser:
        return LucideIcons.shoppingCart;
      case CompanyRole.viewer:
        return LucideIcons.eye;
    }
  }
}
