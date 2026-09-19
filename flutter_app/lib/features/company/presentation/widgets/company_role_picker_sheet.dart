import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/i18n/locale_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../domain/value_objects/company_role.dart';
import 'company_role_x.dart';

/// Role picker for the requester/director-facing flows (Join Company,
/// Director approval's role override, Invite Employee) — modeled on
/// `features/employees/presentation/widgets/employee_role_picker_sheet.dart`.
/// Deliberately offers every [CompanyRole] value — `owner` was never
/// added to that enum in the first place (see its own header comment),
/// so there's nothing to exclude here.
class CompanyRolePickerSheet extends ConsumerWidget {
  const CompanyRolePickerSheet({super.key, this.current, this.title});

  final CompanyRole? current;
  final String? title;

  static Future<CompanyRole?> open(
    BuildContext context, {
    CompanyRole? current,
    String? title,
  }) {
    return showAppBottomSheet<CompanyRole>(
      context: context,
      child: CompanyRolePickerSheet(current: current, title: title),
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
          title ?? strings.joinCompanySelectRoleTitle,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.lg),
        for (final role in CompanyRole.values)
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
