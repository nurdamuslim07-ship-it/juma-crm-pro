import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/i18n/locale_provider.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../domain/value_objects/salary_type.dart';
import 'salary_type_x.dart';

class SalaryTypePickerSheet extends ConsumerWidget {
  const SalaryTypePickerSheet({super.key, this.current});

  final SalaryType? current;

  static Future<SalaryType?> open(BuildContext context, {SalaryType? current}) {
    return showAppBottomSheet<SalaryType>(
      context: context,
      child: SalaryTypePickerSheet(current: current),
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
          strings.employeeSelectSalaryTypeTitle,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.lg),
        for (final type in SalaryType.values)
          ListTile(
            onTap: () => Navigator.of(context).pop(type),
            trailing: type == current
                ? const Icon(LucideIcons.check, size: 18)
                : null,
            title: Text(
              type.label(strings),
              style: TextStyle(
                fontWeight: type == current ? FontWeight.w700 : null,
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
