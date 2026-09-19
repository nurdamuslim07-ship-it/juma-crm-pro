import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/widgets/press_motion.dart';
import '../../../order_workflow/order_workflow_screen.dart';
import '../../../order_workflow/workflow_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/i18n/locale_provider.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/launchers.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../payments/presentation/widgets/payment_history_section.dart';
import '../../domain/entities/customer_order.dart';
import '../providers/order_providers.dart';
import '../widgets/order_payment_progress.dart';
import '../widgets/order_status_badge.dart';
import '../widgets/order_status_picker_sheet.dart';

class OrderDetailScreen extends ConsumerWidget {
  const OrderDetailScreen({super.key, required this.orderId});
  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final orderAsync = ref.watch(orderDetailProvider(orderId));

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: Text(strings.navOrders),
      ),
      body: orderAsync.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorView(
          message: strings.orderNotFound,
          retryLabel: strings.commonRetry,
          onRetry: () => ref.invalidate(orderDetailProvider(orderId)),
        ),
        data: (order) => _OrderDetailBody(order: order),
      ),
    );
  }
}

class _OrderDetailBody extends ConsumerWidget {
  const _OrderDetailBody({required this.order});
  final CustomerOrder order;

  Future<void> _changeStatus(BuildContext context, WidgetRef ref) async {
    final strings = ref.read(appStringsProvider);
    final newStatus = await OrderStatusPickerSheet.open(
      context,
      currentStatus: order.status,
    );
    if (newStatus == null || newStatus == order.status) return;

    final result = await ref
        .read(updateOrderStatusUseCaseProvider)
        .call(order.id, newStatus);
    if (!context.mounted) return;

    result.match(
      (failure) => AppToast.show(failure.message, tone: ToastTone.error),
      (_) {
        AppToast.show(strings.orderStatusUpdatedToast, tone: ToastTone.success);
        ref.invalidate(orderDetailProvider(order.id));
        ref.invalidate(ordersListProvider);
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final strings = ref.read(appStringsProvider);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.orderDeleteConfirmTitle),
        content: Text(strings.orderDeleteConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(strings.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              strings.commonDelete,
              style: const TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final result = await ref.read(deleteOrderUseCaseProvider).call(order.id);
    if (!context.mounted) return;

    result.match(
      (failure) => AppToast.show(failure.message, tone: ToastTone.error),
      (_) {
        AppToast.show(strings.orderDeletedToast, tone: ToastTone.success);
        ref.invalidate(ordersListProvider);
        context.pop(true);
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: FilledButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => OrderWorkflowScreen(orderId: order.id),
                  ),
                ),
                icon: const Icon(Icons.timeline),
                label: Text(ref.watch(workflowStringsProvider).title),
              ),
            ),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              order.orderNumber,
                              style: textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondaryLight,
                              ),
                            ),
                            Text(
                              order.productType,
                              style: textTheme.headlineSmall,
                            ),
                          ],
                        ),
                      ),
                      MotionInkWell(
                        onTap: () => _changeStatus(context, ref),
                        borderRadius: BorderRadius.circular(999),
                        child: OrderStatusBadge(status: order.status),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          label: order.clientName,
                          icon: LucideIcons.phone,
                          variant: AppButtonVariant.secondary,
                          onPressed: () async {
                            final ok = await AppLaunchers.call(
                              order.clientPhone,
                            );
                            if (!ok && context.mounted) {
                              AppToast.show(
                                strings.commonCannotOpenLink,
                                tone: ToastTone.error,
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            GlassCard(child: OrderPaymentProgress(order: order)),
            const SizedBox(height: AppSpacing.lg),
            PaymentHistorySection(
              orderId: order.id,
              clientId: order.clientId,
              orderTotalTiyn: order.totalAmountTiyn,
              alreadyPaidTiyn: order.paidTiyn,
              onChanged: () => ref.invalidate(orderDetailProvider(order.id)),
            ),
            const SizedBox(height: AppSpacing.lg),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoRow(
                    icon: LucideIcons.ruler,
                    label: strings.orderFormMeasurementDateLabel,
                    value: order.measurementDate != null
                        ? AppFormatters.date(order.measurementDate!)
                        : '—',
                  ),
                  _InfoRow(
                    icon: LucideIcons.calendarCheck,
                    label: strings.orderFormPlannedCompletionDateLabel,
                    value: order.plannedCompletionDate != null
                        ? AppFormatters.date(order.plannedCompletionDate!)
                        : '—',
                  ),
                  _InfoRow(
                    icon: LucideIcons.userCog,
                    label: strings.orderFormResponsibleEmployeeLabel,
                    value:
                        order.responsibleEmployeeName ??
                        strings.orderNoEmployeeAssigned,
                  ),
                  _InfoRow(
                    icon: LucideIcons.stickyNote,
                    label: strings.orderFormNotesLabel,
                    value: order.description?.isNotEmpty == true
                        ? order.description!
                        : '—',
                    isLast: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: strings.commonEdit,
              icon: LucideIcons.pencil,
              variant: AppButtonVariant.secondary,
              onPressed: () async {
                final changed = await context.push<bool>(
                  RoutePaths.orderEdit(order.id),
                  extra: order,
                );
                if (changed == true) {
                  ref.invalidate(orderDetailProvider(order.id));
                  ref.invalidate(ordersListProvider);
                }
              },
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: strings.commonDelete,
              icon: LucideIcons.trash2,
              variant: AppButtonVariant.destructive,
              onPressed: () => _confirmDelete(context, ref),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isLast = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondaryLight),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: textTheme.bodySmall),
                Text(value, style: textTheme.bodyLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
