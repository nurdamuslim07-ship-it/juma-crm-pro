import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/i18n/locale_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../employees/presentation/widgets/employee_role_x.dart';
import '../../domain/entities/employee_kpi.dart';

/// Requirement: "Қызметкерлер бойынша KPI" — one card per employee
/// (`get_employee_kpis()` already scopes the list to just the caller's
/// own row unless they hold `analytics.read_all_kpi`, so this widget
/// never needs its own role check — it renders whatever came back).
class EmployeeKpiSection extends ConsumerWidget {
  const EmployeeKpiSection({super.key, required this.kpis});

  final List<EmployeeKpi> kpis;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings.analyticsEmployeeKpiTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          if (kpis.isEmpty)
            Text(
              strings.analyticsNoDataForPeriod,
              style: Theme.of(context).textTheme.bodyMedium,
            )
          else
            for (final kpi in kpis) _EmployeeKpiTile(kpi: kpi),
        ],
      ),
    );
  }
}

class _EmployeeKpiTile extends ConsumerWidget {
  const _EmployeeKpiTile({required this.kpi});
  final EmployeeKpi kpi;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            kpi.role?.icon ?? LucideIcons.user,
            size: 18,
            color: AppColors.textSecondaryLight,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(kpi.fullName, style: textTheme.bodyLarge),
                if (kpi.role != null)
                  Text(kpi.role!.label(strings), style: textTheme.bodySmall),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${strings.analyticsOrdersAssignedLabel}: '
                  '${kpi.ordersAssignedCount} · '
                  '${strings.analyticsOrdersCompletedLabel}: '
                  '${kpi.ordersCompletedCount}',
                  style: textTheme.bodySmall,
                ),
                if (kpi.hasPaymentsFigures &&
                    (kpi.paymentsRecordedCount ?? 0) > 0)
                  Text(
                    '${strings.analyticsPaymentsRecordedLabel}: '
                    '${kpi.paymentsRecordedCount} '
                    '(${AppFormatters.tenge(kpi.paymentsRecordedAmountTiyn ?? 0)})',
                    style: textTheme.bodySmall,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
