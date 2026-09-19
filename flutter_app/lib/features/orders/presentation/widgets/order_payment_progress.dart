import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/i18n/locale_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/customer_order.dart';

/// Payment progress only — deliberately NOT paired with a production-
/// percent bar in this module (that axis lives in
/// `order_production_progress`, wired up by a later production-queue
/// feature, not requested for this pass). Per ORDER_WORKFLOW.md /
/// CLAUDE.md, payment % must never be silently treated as "overall
/// progress" — this widget's own label always says "Төлем пайызы"
/// (payment percentage), never a bare "Прогресс".
class OrderPaymentProgress extends ConsumerWidget {
  const OrderPaymentProgress({super.key, required this.order});

  final CustomerOrder order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              strings.orderPaymentProgressLabel,
              style: textTheme.bodyMedium,
            ),
            Text(
              AppFormatters.percent(order.paymentPercent),
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: LinearProgressIndicator(
            value: order.paymentPercent / 100,
            minHeight: 8,
            backgroundColor: AppColors.textSecondaryLight.withValues(
              alpha: 0.15,
            ),
            valueColor: AlwaysStoppedAnimation(
              order.remainingTiyn == 0 ? AppColors.success : AppColors.skyDeep,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _AmountColumn(
                label: strings.orderPaidLabel,
                value: AppFormatters.tenge(order.paidTiyn),
                color: AppColors.success,
              ),
            ),
            Expanded(
              child: _AmountColumn(
                label: strings.orderRemainingLabel,
                value: AppFormatters.tenge(order.remainingTiyn),
                color: order.remainingTiyn == 0
                    ? AppColors.success
                    : AppColors.warning,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AmountColumn extends StatelessWidget {
  const _AmountColumn({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
