import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/i18n/locale_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../domain/value_objects/partner_category.dart';
import 'partner_category_x.dart';

/// Requirement: "Санат ... bottom sheet арқылы таңдалсын". [allowAll]
/// shows the "Барлығы" ("all categories") tile used by the list
/// screen's filter — the create/edit form passes `allowAll: false`
/// since a partner's category is required, not optional.
class PartnerCategoryPickerSheet extends ConsumerWidget {
  const PartnerCategoryPickerSheet({
    super.key,
    this.current,
    this.allowAll = true,
  });

  final PartnerCategory? current;
  final bool allowAll;

  static Future<Object?> open(
    BuildContext context, {
    PartnerCategory? current,
    bool allowAll = true,
  }) {
    return showAppBottomSheet<Object>(
      context: context,
      child: PartnerCategoryPickerSheet(current: current, allowAll: allowAll),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);

    Widget tile(String label, PartnerCategory? value, {IconData? icon}) {
      return ListTile(
        onTap: () => Navigator.of(context).pop(_PickedCategory(value)),
        leading: icon != null
            ? Icon(
                icon,
                color: value == current
                    ? AppColors.skyDeep
                    : AppColors.textSecondaryLight,
              )
            : null,
        trailing: value == current
            ? const Icon(LucideIcons.check, size: 18)
            : null,
        title: Text(
          label,
          style: TextStyle(
            fontWeight: value == current ? FontWeight.w700 : null,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          strings.partnerSelectCategoryTitle,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.lg),
        if (allowAll) tile(strings.partnerFilterAllCategories, null),
        for (final category in PartnerCategory.values)
          tile(category.label(strings), category, icon: category.icon),
      ],
    );
  }
}

class _PickedCategory {
  const _PickedCategory(this.value);
  final PartnerCategory? value;
}

({bool picked, PartnerCategory? value}) unwrapPickedCategory(Object? result) {
  if (result is _PickedCategory) return (picked: true, value: result.value);
  return (picked: false, value: null);
}
