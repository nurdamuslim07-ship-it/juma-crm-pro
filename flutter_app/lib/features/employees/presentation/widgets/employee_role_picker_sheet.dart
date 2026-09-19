import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/i18n/locale_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../domain/value_objects/employee_role.dart';
import 'employee_role_x.dart';

/// Requirement: "Bottom sheet арқылы рөл ... таңдау".
class EmployeeRolePickerSheet extends ConsumerWidget {
  const EmployeeRolePickerSheet({super.key, this.current});

  final EmployeeRole? current;

  static Future<EmployeeRole?> open(
    BuildContext context, {
    EmployeeRole? current,
  }) {
    return showAppBottomSheet<EmployeeRole>(
      context: context,
      child: EmployeeRolePickerSheet(current: current),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          strings.employeeSelectRoleTitle,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.lg),
        for (final role in EmployeeRole.values)
          ListTile(
            onTap: () => Navigator.of(context).pop(role),
            leading: Icon(
              role.icon,
              color: role == current
                  ? AppColors.skyDeep
                  : AppColors.textSecondaryLight,
            ),
            trailing: role == current
                ? const Icon(LucideIcons.check, size: 18)
                : null,
            title: Text(
              role.label(strings),
              style: TextStyle(
                fontWeight: role == current ? FontWeight.w700 : null,
              ),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
      ],
    );
  }
}
