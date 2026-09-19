import '../../../../core/widgets/press_motion.dart';
import 'package:flutter/material.dart';

import '../../../../core/i18n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../domain/entities/purchase_order_summary.dart';
import 'purchase_order_status_x.dart';

/// Requirement: "Планшет/Desktop: Data Table" — same reasoning as
/// Warehouse's `materials_table.dart`: purchase orders are tabular/
/// numeric records with a linear status progression, not a
/// multi-column workflow board, so Table (not Kanban) is the right
/// tablet/desktop layout.
class PurchaseOrdersTable extends StatelessWidget {
  const PurchaseOrdersTable({
    super.key,
    required this.orders,
    required this.onRowTap,
    required this.strings,
    required this.columnNumber,
    required this.columnSupplier,
    required this.columnStatus,
    required this.columnTotal,
    required this.columnExpectedDate,
  });

  final List<PurchaseOrderSummary> orders;
  final ValueChanged<PurchaseOrderSummary> onRowTap;
  final AppStrings strings;
  final String columnNumber;
  final String columnSupplier;
  final String columnStatus;
  final String columnTotal;
  final String columnExpectedDate;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final headerStyle = textTheme.bodySmall?.copyWith(
      fontWeight: FontWeight.w700,
      color: AppColors.textSecondaryLight,
    );

    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(flex: 2, child: Text(columnNumber, style: headerStyle)),
              Expanded(
                flex: 3,
                child: Text(columnSupplier, style: headerStyle),
              ),
              Expanded(flex: 2, child: Text(columnStatus, style: headerStyle)),
              Expanded(
                child: Text(
                  columnTotal,
                  style: headerStyle,
                  textAlign: TextAlign.right,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(columnExpectedDate, style: headerStyle),
              ),
            ],
          ),
          const Divider(height: AppSpacing.lg),
          for (final order in orders)
            MotionInkWell(
              onTap: () => onRowTap(order),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        order.orderNumber,
                        style: textTheme.bodyMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        order.supplierName,
                        style: textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Row(
                        children: [
                          Icon(
                            order.status.icon,
                            size: 14,
                            color: AppColors.skyDeep,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: Text(
                              order.status.nameKk(strings),
                              style: textTheme.bodySmall,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '${(order.totalAmountTiyn / 100).toStringAsFixed(0)} ₸',
                        textAlign: TextAlign.right,
                        style: textTheme.bodyMedium,
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        order.expectedDeliveryDate == null
                            ? '—'
                            : '${order.expectedDeliveryDate!.day.toString().padLeft(2, '0')}.${order.expectedDeliveryDate!.month.toString().padLeft(2, '0')}.${order.expectedDeliveryDate!.year}',
                        style: textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
