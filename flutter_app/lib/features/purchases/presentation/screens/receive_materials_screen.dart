import '../../../../core/widgets/app_back_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/i18n/locale_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/state_views.dart';
import '../../domain/entities/purchase_order_status.dart';
import '../providers/purchases_providers.dart';

/// Requirement: "Receive Materials" screen — a review step before
/// `receive_purchase_order()` is called: confirms every line item's
/// material/quantity/location, since receiving is the one action that
/// writes to inventory_batches/inventory_transactions/inventory_balances
/// (via Warehouse's own receive_materials(), reused per item) and
/// cannot be undone by re-editing the order afterward (it's no longer
/// a draft).
class ReceiveMaterialsScreen extends ConsumerStatefulWidget {
  const ReceiveMaterialsScreen({super.key, required this.orderId});
  final String orderId;

  @override
  ConsumerState<ReceiveMaterialsScreen> createState() =>
      _ReceiveMaterialsScreenState();
}

class _ReceiveMaterialsScreenState
    extends ConsumerState<ReceiveMaterialsScreen> {
  bool _saving = false;

  Future<void> _confirm() async {
    final strings = ref.read(appStringsProvider);
    setState(() => _saving = true);
    final result = await ref
        .read(receivePurchaseOrderUseCaseProvider)
        .call(widget.orderId);
    if (!mounted) return;
    setState(() => _saving = false);
    result.match(
      (failure) => AppToast.show(failure.message, tone: ToastTone.error),
      (_) {
        AppToast.show(strings.purchasesReceivedToast, tone: ToastTone.success);
        ref.invalidate(purchaseOrderDetailProvider(widget.orderId));
        ref.invalidate(purchaseOrdersListProvider);
        ref.invalidate(pendingPurchaseQuantitiesProvider);
        Navigator.of(context).pop();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);
    final textTheme = Theme.of(context).textTheme;
    final detailAsync = ref.watch(purchaseOrderDetailProvider(widget.orderId));

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: Text(strings.purchasesReceiveConfirmTitle),
      ),
      body: detailAsync.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorView(
          message: strings.purchasesOrderNotFound,
          retryLabel: strings.commonRetry,
          onRetry: () =>
              ref.invalidate(purchaseOrderDetailProvider(widget.orderId)),
        ),
        data: (detail) {
          if (detail.status != PurchaseOrderStatus.delivered) {
            return Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    LucideIcons.alertTriangle,
                    size: 40,
                    color: AppColors.danger,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    strings.purchasesReceiveGuardMessage,
                    style: textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppButton(
                    label: strings.commonBack,
                    icon: LucideIcons.arrowLeft,
                    variant: AppButtonVariant.secondary,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Text(
                strings.purchasesReceiveConfirmBody,
                style: textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.lg),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.purchasesItemsTitle,
                      style: textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    for (final item in detail.items)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: Row(
                          children: [
                            Icon(
                              item.locationId == null
                                  ? LucideIcons.alertTriangle
                                  : LucideIcons.packageCheck,
                              size: 16,
                              color: item.locationId == null
                                  ? AppColors.danger
                                  : AppColors.success,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                item.materialName ?? '',
                                style: textTheme.bodyMedium,
                              ),
                            ),
                            Text(
                              '${item.quantity} ${item.unit}',
                              style: textTheme.bodySmall,
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Text(
                              item.locationName ??
                                  strings.purchasesLocationRequiredError,
                              style: textTheme.bodySmall?.copyWith(
                                color: item.locationId == null
                                    ? AppColors.danger
                                    : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                label: strings.purchasesReceiveAction,
                icon: LucideIcons.packageCheck,
                loading: _saving,
                onPressed: _confirm,
              ),
            ],
          );
        },
      ),
    );
  }
}
