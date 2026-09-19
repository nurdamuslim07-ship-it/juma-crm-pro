import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/i18n/locale_provider.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../domain/analytics_period.dart';
import 'analytics_period_type_x.dart';

/// Requirement: "Күн, апта, ай, жыл бойынша фильтр".
class AnalyticsPeriodPickerSheet extends ConsumerWidget {
  const AnalyticsPeriodPickerSheet({super.key, required this.current});

  final AnalyticsPeriodType current;

  static Future<AnalyticsPeriodType?> open(
    BuildContext context, {
    required AnalyticsPeriodType current,
  }) {
    return showAppBottomSheet<AnalyticsPeriodType>(
      context: context,
      child: AnalyticsPeriodPickerSheet(current: current),
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
          strings.analyticsSelectPeriodTitle,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.lg),
        for (final type in AnalyticsPeriodType.values)
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
