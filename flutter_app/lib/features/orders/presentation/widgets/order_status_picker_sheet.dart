import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/i18n/locale_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../domain/value_objects/order_status.dart';
import '../providers/order_providers.dart';
import 'order_status_x.dart';

/// Only *offers* statuses [allowedOrderStatusesProvider] says the
/// current user's roles may set (see ORDER_WORKFLOW.md's per-status
/// role table) — purely a convenience so nobody taps something the
/// server will reject; the `orders_status_transition_guard` trigger
/// is the actual enforcement regardless of what this sheet shows.
class OrderStatusPickerSheet extends ConsumerWidget {
  const OrderStatusPickerSheet({super.key, required this.currentStatus});

  final OrderStatus currentStatus;

  static Future<OrderStatus?> open(
    BuildContext context, {
    required OrderStatus currentStatus,
  }) {
    return showAppBottomSheet<OrderStatus>(
      context: context,
      child: OrderStatusPickerSheet(currentStatus: currentStatus),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final allowed = ref.watch(allowedOrderStatusesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          strings.orderChangeStatusTitle,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.lg),
        for (final status in OrderStatus.values)
          ListTile(
            enabled: allowed.contains(status),
            onTap: () => Navigator.of(context).pop(status),
            leading: Icon(
              status == currentStatus
                  ? LucideIcons.checkCircle2
                  : LucideIcons.circle,
              color: allowed.contains(status)
                  ? status.color
                  : AppColors.textSecondaryLight,
            ),
            title: Text(
              status.label(strings),
              style: TextStyle(
                fontWeight: status == currentStatus ? FontWeight.w700 : null,
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
