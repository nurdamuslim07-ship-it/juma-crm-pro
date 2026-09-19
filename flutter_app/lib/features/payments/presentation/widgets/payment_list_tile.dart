import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/i18n/locale_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../domain/entities/payment.dart';
import 'payment_method_x.dart';

class PaymentListTile extends ConsumerWidget {
  const PaymentListTile({
    super.key,
    required this.payment,
    this.onTap,
    this.showOrderInfo = true,
  });

  final Payment payment;
  final VoidCallback? onTap;

  /// The order-detail payment history hides the order/client line
  /// since it's already obvious from context; the global Payments tab
  /// shows it.
  final bool showOrderInfo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: GlassCard(
        onTap: onTap,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Icon(
                payment.method.icon,
                size: 20,
                color: AppColors.success,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showOrderInfo) ...[
                    Text(
                      payment.clientName,
                      style: textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      payment.orderNumber,
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                  ] else
                    Text(
                      payment.method.label(strings),
                      style: textTheme.titleMedium,
                    ),
                  Text(
                    AppFormatters.date(payment.paidAt),
                    style: textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  AppFormatters.tenge(payment.amountTiyn),
                  style: textTheme.titleMedium?.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (showOrderInfo)
                  Text(
                    payment.method.label(strings),
                    style: textTheme.bodySmall,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
