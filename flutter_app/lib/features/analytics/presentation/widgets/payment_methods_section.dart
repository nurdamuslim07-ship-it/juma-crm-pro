import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/i18n/locale_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../payments/domain/value_objects/payment_method.dart';
import '../../../payments/presentation/widgets/payment_method_x.dart';
import '../../domain/entities/payment_method_stat.dart';

const _palette = [
  AppColors.skyDeep,
  AppColors.indigo,
  AppColors.teal,
  AppColors.warning,
  AppColors.textSecondaryLight,
];

/// Requirement: "Төлем әдістері бойынша статистика" — a plain
/// breakdown list on phone, a pie chart on tablet/web.
class PaymentMethodsSection extends ConsumerWidget {
  const PaymentMethodsSection({super.key, required this.stats});

  final Map<PaymentMethod, PaymentMethodStat> stats;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final totalAmount = stats.values.fold(0, (a, b) => a + b.amountTiyn);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings.analyticsPaymentMethodsTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          if (stats.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Text(
                strings.analyticsNoDataForPeriod,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            )
          else if (context.isMobile)
            _MethodList(stats: stats, totalAmount: totalAmount)
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 140,
                  height: 140,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 32,
                      sections: [
                        for (final entry in stats.entries)
                          PieChartSectionData(
                            value: entry.value.amountTiyn.toDouble(),
                            color: _colorFor(entry.key),
                            title: '',
                            radius: 28,
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: _MethodList(stats: stats, totalAmount: totalAmount),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Color _colorFor(PaymentMethod method) {
    return _palette[method.index % _palette.length];
  }
}

class _MethodList extends ConsumerWidget {
  const _MethodList({required this.stats, required this.totalAmount});

  final Map<PaymentMethod, PaymentMethodStat> stats;
  final int totalAmount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    return Column(
      children: [
        for (final entry in stats.entries)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              children: [
                Icon(entry.key.icon, size: 16),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    '${entry.key.label(strings)} (${_percentOf(entry.value.amountTiyn)}%)',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                Text(
                  AppFormatters.tenge(entry.value.amountTiyn),
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
      ],
    );
  }

  int _percentOf(int amountTiyn) {
    if (totalAmount == 0) return 0;
    return (amountTiyn / totalAmount * 100).round();
  }
}
