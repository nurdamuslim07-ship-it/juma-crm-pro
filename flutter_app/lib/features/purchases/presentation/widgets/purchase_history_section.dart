import '../../../../core/widgets/press_motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/i18n/locale_provider.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/state_views.dart';
import '../providers/purchases_providers.dart';
import 'purchase_order_status_x.dart';

/// Requirement: Partners integration — "Supplier карточкасынан: Purchase
/// History ... көру" — reuses `get_purchase_orders(p_supplier_partner_id)`
/// via [purchaseOrdersBySupplierProvider] (deliberately separate from
/// the main Purchase Orders screen's list provider — see that
/// provider's doc comment).
class PurchaseHistorySection extends ConsumerWidget {
  const PurchaseHistorySection({super.key, required this.partnerId});
  final String partnerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final textTheme = Theme.of(context).textTheme;
    final ordersAsync = ref.watch(purchaseOrdersBySupplierProvider(partnerId));

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings.purchasesPurchaseHistoryTitle,
            style: textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          ordersAsync.when(
            loading: () => const LoadingView(),
            error: (error, _) => Text(strings.purchasesLoadError),
            data: (orders) {
              if (orders.isEmpty) {
                return Text(
                  strings.purchasesNoPurchaseHistory,
                  style: textTheme.bodyMedium,
                );
              }
              return Column(
                children: [
                  for (final order in orders)
                    MotionInkWell(
                      onTap: () => context.push(
                        RoutePaths.purchaseOrderDetail(order.id),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: Row(
                          children: [
                            Icon(
                              order.status.icon,
                              size: 16,
                              color: AppColors.skyDeep,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    order.orderNumber,
                                    style: textTheme.bodyMedium,
                                  ),
                                  Text(
                                    order.status.nameKk(strings),
                                    style: textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${(order.totalAmountTiyn / 100).toStringAsFixed(0)} ₸',
                              style: textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
