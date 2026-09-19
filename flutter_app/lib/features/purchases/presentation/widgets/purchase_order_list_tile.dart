import 'package:flutter/material.dart';

import '../../../../core/i18n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../domain/entities/purchase_order_summary.dart';
import 'purchase_order_status_x.dart';

/// Requirement: "Телефон: Card List".
class PurchaseOrderListTile extends StatelessWidget {
  const PurchaseOrderListTile({
    super.key,
    required this.order,
    required this.strings,
    this.onTap,
  });

  final PurchaseOrderSummary order;
  final AppStrings strings;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: GlassCard(
        onTap: onTap,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Icon(order.status.icon, color: AppColors.skyDeep),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.orderNumber,
                    style: textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(order.supplierName, style: textTheme.bodySmall),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${(order.totalAmountTiyn / 100).toStringAsFixed(0)} ₸',
                  style: textTheme.bodyLarge,
                ),
                Text(
                  order.status.nameKk(strings),
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
