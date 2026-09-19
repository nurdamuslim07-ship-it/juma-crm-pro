import '../../../../core/widgets/app_back_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/i18n/locale_provider.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/purchase_order_detail.dart';
import '../../domain/entities/purchase_order_status.dart';
import '../../domain/entities/supplier_invoice.dart';
import '../../domain/entities/supplier_invoice_status.dart';
import '../providers/purchases_providers.dart';
import '../widgets/purchase_order_status_x.dart';
import '../widgets/record_supplier_payment_sheet.dart';

/// Requirement: "Purchase Detail" screen — financial breakdown, items,
/// and the status-transition actions (Бекіту/Бас тарту/Жеткізілді/
/// Қабылдау/жою), each gated on the matching permission per the role
/// matrix (see purchases_providers.dart's PurchasesAccess extension).
class PurchaseOrderDetailScreen extends ConsumerWidget {
  const PurchaseOrderDetailScreen({super.key, required this.orderId});
  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final detailAsync = ref.watch(purchaseOrderDetailProvider(orderId));

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: Text(strings.purchasesDetailTitle),
      ),
      body: detailAsync.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorView(
          message: strings.purchasesOrderNotFound,
          retryLabel: strings.commonRetry,
          onRetry: () => ref.invalidate(purchaseOrderDetailProvider(orderId)),
        ),
        data: (detail) => _DetailBody(detail: detail),
      ),
    );
  }
}

class _DetailBody extends ConsumerWidget {
  const _DetailBody({required this.detail});
  final PurchaseOrderDetail detail;

  Future<String?> _promptReason(
    BuildContext context,
    WidgetRef ref,
    String title,
    String label,
  ) {
    final strings = ref.read(appStringsProvider);
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(labelText: label),
          maxLines: 2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(strings.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: Text(strings.commonConfirm),
          ),
        ],
      ),
    );
  }

  void _refresh(WidgetRef ref) {
    ref.invalidate(purchaseOrderDetailProvider(detail.id));
    ref.invalidate(purchaseOrdersListProvider);
    ref.invalidate(pendingPurchaseQuantitiesProvider);
  }

  Future<void> _approve(BuildContext context, WidgetRef ref) async {
    final strings = ref.read(appStringsProvider);
    final result = await ref
        .read(approvePurchaseOrderUseCaseProvider)
        .call(detail.id);
    if (!context.mounted) return;
    result.match(
      (failure) => AppToast.show(failure.message, tone: ToastTone.error),
      (_) {
        AppToast.show(strings.purchasesApprovedToast, tone: ToastTone.success);
        _refresh(ref);
      },
    );
  }

  Future<void> _reject(BuildContext context, WidgetRef ref) async {
    final strings = ref.read(appStringsProvider);
    final reason = await _promptReason(
      context,
      ref,
      strings.purchasesConfirmRejectTitle,
      strings.purchasesReasonLabel,
    );
    if (reason == null || !context.mounted) return;
    final result = await ref
        .read(rejectPurchaseOrderUseCaseProvider)
        .call(detail.id, reason: reason.isEmpty ? null : reason);
    if (!context.mounted) return;
    result.match(
      (failure) => AppToast.show(failure.message, tone: ToastTone.error),
      (_) {
        AppToast.show(strings.purchasesRejectedToast, tone: ToastTone.success);
        _refresh(ref);
      },
    );
  }

  Future<void> _deliver(BuildContext context, WidgetRef ref) async {
    final strings = ref.read(appStringsProvider);
    final result = await ref
        .read(markPurchaseOrderDeliveredUseCaseProvider)
        .call(detail.id);
    if (!context.mounted) return;
    result.match(
      (failure) => AppToast.show(failure.message, tone: ToastTone.error),
      (_) {
        AppToast.show(strings.purchasesDeliveredToast, tone: ToastTone.success);
        _refresh(ref);
      },
    );
  }

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    final strings = ref.read(appStringsProvider);
    final reason = await _promptReason(
      context,
      ref,
      strings.purchasesConfirmCancelTitle,
      strings.purchasesReasonLabel,
    );
    if (reason == null || !context.mounted) return;
    final result = await ref
        .read(cancelPurchaseOrderUseCaseProvider)
        .call(detail.id, reason: reason.isEmpty ? null : reason);
    if (!context.mounted) return;
    result.match(
      (failure) => AppToast.show(failure.message, tone: ToastTone.error),
      (_) {
        AppToast.show(strings.purchasesCancelledToast, tone: ToastTone.success);
        _refresh(ref);
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final textTheme = Theme.of(context).textTheme;
    final currentUser = ref.watch(currentUserProvider);
    final canWrite = currentUser?.canWritePurchases ?? false;
    final canApprove = currentUser?.canApprovePurchases ?? false;
    final canReceive = currentUser?.canReceivePurchases ?? false;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(detail.orderNumber, style: textTheme.titleLarge),
                        Text(detail.supplierName, style: textTheme.bodyMedium),
                      ],
                    ),
                  ),
                  Icon(detail.status.icon, color: AppColors.skyDeep, size: 28),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                detail.status.nameKk(strings),
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.skyDeep,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _row(
                context,
                strings.purchasesCreatedAtLabel,
                AppFormatters.date(detail.createdAt),
              ),
              _row(
                context,
                strings.purchasesResponsibleEmployeeLabel,
                detail.responsibleEmployeeName ??
                    strings.purchasesNoResponsibleEmployee,
              ),
              _row(
                context,
                strings.purchasesExpectedDeliveryLabel,
                detail.expectedDeliveryDate == null
                    ? strings.purchasesNoExpectedDelivery
                    : _formatDate(detail.expectedDeliveryDate!),
              ),
              if (detail.comment != null)
                _row(context, strings.purchasesCommentLabel, detail.comment!),
              if (detail.rejectionReason != null)
                _row(
                  context,
                  strings.purchasesRejectionReasonLabel,
                  detail.rejectionReason!,
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _moneyRow(
                context,
                strings.purchasesSubtotalLabel,
                detail.subtotalTiyn,
              ),
              _moneyRow(
                context,
                strings.purchasesDeliveryCostLabel,
                detail.deliveryCostTiyn,
              ),
              _moneyRow(context, strings.purchasesVatLabel, detail.vatTiyn),
              _moneyRow(
                context,
                strings.purchasesDiscountLabel,
                -detail.discountTiyn,
              ),
              const Divider(height: AppSpacing.lg),
              _moneyRow(
                context,
                strings.purchasesTotalLabel,
                detail.totalAmountTiyn,
                emphasize: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(strings.purchasesItemsTitle, style: textTheme.titleMedium),
              const SizedBox(height: AppSpacing.md),
              if (detail.items.isEmpty)
                Text(strings.purchasesNoItems, style: textTheme.bodyMedium)
              else
                for (final item in detail.items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.materialName ?? '',
                                style: textTheme.bodyMedium,
                              ),
                              if (item.locationName != null)
                                Text(
                                  item.locationName!,
                                  style: textTheme.bodySmall,
                                ),
                            ],
                          ),
                        ),
                        Text(
                          '${item.quantity} ${item.unit}',
                          style: textTheme.bodySmall,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Text(
                          '${((item.totalPriceTiyn ?? 0) / 100).toStringAsFixed(0)} ₸',
                          style: textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _SupplierFinancialsSection(detail: detail),
        const SizedBox(height: AppSpacing.xl),
        if (detail.status == PurchaseOrderStatus.draft && canWrite)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: AppButton(
              label: strings.purchasesEditAction,
              icon: LucideIcons.pencil,
              variant: AppButtonVariant.secondary,
              onPressed: () => context.push(
                RoutePaths.purchaseOrderEdit(detail.id),
                extra: detail,
              ),
            ),
          ),
        if (detail.status == PurchaseOrderStatus.draft && canApprove) ...[
          AppButton(
            label: strings.purchasesApproveAction,
            icon: LucideIcons.checkCircle2,
            onPressed: () => _approve(context, ref),
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: strings.purchasesRejectAction,
            icon: LucideIcons.xCircle,
            variant: AppButtonVariant.destructive,
            onPressed: () => _reject(context, ref),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        if (detail.status == PurchaseOrderStatus.approved && canApprove) ...[
          AppButton(
            label: strings.purchasesDeliverAction,
            icon: LucideIcons.truck,
            onPressed: () => _deliver(context, ref),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        if (detail.status == PurchaseOrderStatus.delivered && canReceive) ...[
          AppButton(
            label: strings.purchasesReceiveAction,
            icon: LucideIcons.packageCheck,
            onPressed: () =>
                context.push(RoutePaths.purchaseOrderReceive(detail.id)),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        if ((detail.status == PurchaseOrderStatus.draft ||
                detail.status == PurchaseOrderStatus.approved ||
                detail.status == PurchaseOrderStatus.delivered) &&
            (canWrite || canApprove))
          AppButton(
            label: strings.purchasesCancelAction,
            icon: LucideIcons.ban,
            variant: AppButtonVariant.destructive,
            onPressed: () => _cancel(context, ref),
          ),
      ],
    );
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';

  Widget _row(BuildContext context, String label, String value) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            LucideIcons.circleDot,
            size: 14,
            color: AppColors.textSecondaryLight,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: textTheme.bodySmall),
                Text(value, style: textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _moneyRow(
    BuildContext context,
    String label,
    int amountTiyn, {
    bool emphasize = false,
  }) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: emphasize
                ? textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700)
                : textTheme.bodyMedium,
          ),
          Text(
            '${(amountTiyn / 100).toStringAsFixed(0)} ₸',
            style: emphasize
                ? textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700)
                : textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

SupplierInvoice? _findLinkedInvoice(
  List<SupplierInvoice> invoices,
  String orderId,
) {
  for (final invoice in invoices) {
    if (invoice.purchaseOrderId == orderId) return invoice;
  }
  return null;
}

/// Requirement: supplier balance + this order's linked invoice/payments
/// on the Purchase Order detail screen. [SupplierBalance] is read
/// through [supplierBalanceProvider] (added alongside `getSupplierBalance`
/// in the Domain/Data stage) — this is its first real UI consumer.
/// Invoice/payments reuse the already-committed
/// `supplierInvoicesProvider`/`supplierPaymentsProvider`, filtered
/// client-side to this order (`SupplierInvoice.purchaseOrderId` /
/// `SupplierPayment.supplierInvoiceId`) rather than a new RPC.
class _SupplierFinancialsSection extends ConsumerWidget {
  const _SupplierFinancialsSection({required this.detail});
  final PurchaseOrderDetail detail;

  void _refresh(WidgetRef ref) {
    ref.invalidate(supplierBalanceProvider(detail.supplierPartnerId));
    ref.invalidate(supplierInvoicesProvider(detail.supplierPartnerId));
    ref.invalidate(supplierPaymentsProvider(detail.supplierPartnerId));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final textTheme = Theme.of(context).textTheme;
    final currentUser = ref.watch(currentUserProvider);
    final canPay = currentUser?.canPayPurchases ?? false;
    final balanceAsync = ref.watch(
      supplierBalanceProvider(detail.supplierPartnerId),
    );
    final invoicesAsync = ref.watch(
      supplierInvoicesProvider(detail.supplierPartnerId),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        balanceAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (error, _) => const SizedBox.shrink(),
          data: (balance) {
            if (balance.balanceTiyn == null) return const SizedBox.shrink();
            final isDebt = balance.isDebt;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: GlassCard(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      strings.purchasesSupplierBalanceTitle,
                      style: textTheme.bodyMedium,
                    ),
                    Text(
                      '${(balance.balanceTiyn!.abs() / 100).toStringAsFixed(0)} ₸',
                      style: textTheme.titleMedium?.copyWith(
                        color: isDebt ? AppColors.danger : AppColors.success,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        invoicesAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (error, _) => const SizedBox.shrink(),
          data: (invoices) {
            final invoice = _findLinkedInvoice(invoices, detail.id);
            if (invoice == null) return const SizedBox.shrink();
            final remainingTiyn = invoice.amountTiyn - invoice.paidAmountTiyn;
            final paymentsAsync = ref.watch(
              supplierPaymentsProvider(detail.supplierPartnerId),
            );
            return GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        strings.purchasesInvoicesTitle,
                        style: textTheme.titleMedium,
                      ),
                      Text(
                        invoice.status == SupplierInvoiceStatus.paid
                            ? strings.purchasesInvoiceStatusPaid
                            : invoice.status == SupplierInvoiceStatus.partial
                            ? strings.purchasesInvoiceStatusPartial
                            : strings.purchasesInvoiceStatusUnpaid,
                        style: textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _moneyLine(
                    context,
                    strings.purchasesInvoiceAmountLabel,
                    invoice.amountTiyn,
                  ),
                  _moneyLine(
                    context,
                    strings.purchasesInvoicePaidLabel,
                    invoice.paidAmountTiyn,
                  ),
                  if (remainingTiyn > 0)
                    _moneyLine(
                      context,
                      strings.purchasesOutstandingBalanceLabel,
                      remainingTiyn,
                      color: AppColors.danger,
                    ),
                  if (canPay && remainingTiyn > 0) ...[
                    const SizedBox(height: AppSpacing.sm),
                    AppButton(
                      label: strings.purchasesPayInvoiceAction,
                      icon: LucideIcons.banknote,
                      variant: AppButtonVariant.secondary,
                      onPressed: () async {
                        final done = await RecordSupplierPaymentSheet.open(
                          context,
                          partnerId: detail.supplierPartnerId,
                          supplierInvoiceId: invoice.id,
                          invoiceRemainingTiyn: remainingTiyn,
                        );
                        if (done == true) _refresh(ref);
                      },
                    ),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    strings.purchasesPaymentsTitle,
                    style: textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  paymentsAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (error, _) => const SizedBox.shrink(),
                    data: (payments) {
                      final linked = payments
                          .where((p) => p.supplierInvoiceId == invoice.id)
                          .toList();
                      if (linked.isEmpty) {
                        return Text(
                          strings.purchasesNoPayments,
                          style: textTheme.bodyMedium,
                        );
                      }
                      return Column(
                        children: [
                          for (final payment in linked)
                            Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppSpacing.xs,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    AppFormatters.date(payment.paidAt),
                                    style: textTheme.bodySmall,
                                  ),
                                  Text(
                                    '${(payment.amountTiyn / 100).toStringAsFixed(0)} ₸',
                                    style: textTheme.bodyMedium?.copyWith(
                                      decoration: payment.isReversed
                                          ? TextDecoration.lineThrough
                                          : null,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _moneyLine(
    BuildContext context,
    String label,
    int amountTiyn, {
    Color? color,
  }) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: textTheme.bodySmall),
          Text(
            '${(amountTiyn / 100).toStringAsFixed(0)} ₸',
            style: textTheme.bodyMedium?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
