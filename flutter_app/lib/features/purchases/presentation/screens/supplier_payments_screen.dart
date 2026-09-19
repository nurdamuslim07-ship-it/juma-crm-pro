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
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../partners/presentation/providers/partner_providers.dart';
import '../../domain/entities/supplier_invoice.dart';
import '../../domain/entities/supplier_invoice_status.dart';
import '../providers/purchases_providers.dart';
import '../widgets/record_supplier_payment_sheet.dart';

/// Requirement: "Supplier Payments" screen — also backs the "Balance/
/// Invoices/Payments" tabs on a supplier's Partner detail screen
/// (same providers, just embedded there instead of pushed as a route).
class SupplierPaymentsScreen extends ConsumerWidget {
  const SupplierPaymentsScreen({super.key, required this.partnerId});
  final String partnerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final partnerAsync = ref.watch(partnerDetailProvider(partnerId));

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: Text(
          partnerAsync.valueOrNull?.displayName ??
              strings.purchasesPaymentsTitle,
        ),
      ),
      body: SupplierPaymentsSection(partnerId: partnerId),
    );
  }
}

/// The embeddable body — reused directly by [SupplierPaymentsScreen]
/// and by the Partners module's supplier-specific detail section.
class SupplierPaymentsSection extends ConsumerWidget {
  const SupplierPaymentsSection({super.key, required this.partnerId});
  final String partnerId;

  Future<void> _reverse(
    BuildContext context,
    WidgetRef ref,
    String paymentId,
  ) async {
    final strings = ref.read(appStringsProvider);
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.purchasesReversePaymentAction),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: strings.purchasesReverseReasonLabel,
          ),
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
    if (reason == null || !context.mounted) return;
    final result = await ref
        .read(reverseSupplierPaymentUseCaseProvider)
        .call(paymentId, reason);
    if (!context.mounted) return;
    result.match(
      (failure) => AppToast.show(failure.message, tone: ToastTone.error),
      (_) {
        AppToast.show(
          strings.purchasesPaymentReversedToast,
          tone: ToastTone.success,
        );
        ref.invalidate(supplierPaymentsProvider(partnerId));
        ref.invalidate(supplierInvoicesProvider(partnerId));
        ref.invalidate(partnerDetailProvider(partnerId));
        ref.invalidate(supplierBalanceProvider(partnerId));
      },
    );
  }

  Future<void> _payInvoice(
    BuildContext context,
    WidgetRef ref,
    SupplierInvoice invoice,
  ) async {
    final done = await RecordSupplierPaymentSheet.open(
      context,
      partnerId: partnerId,
      supplierInvoiceId: invoice.id,
      invoiceRemainingTiyn: invoice.amountTiyn - invoice.paidAmountTiyn,
    );
    if (done == true) {
      ref.invalidate(supplierPaymentsProvider(partnerId));
      ref.invalidate(supplierInvoicesProvider(partnerId));
      ref.invalidate(partnerDetailProvider(partnerId));
      ref.invalidate(supplierBalanceProvider(partnerId));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final textTheme = Theme.of(context).textTheme;
    final currentUser = ref.watch(currentUserProvider);
    final canPay = currentUser?.canPayPurchases ?? false;
    final partnerAsync = ref.watch(partnerDetailProvider(partnerId));
    final invoicesAsync = ref.watch(supplierInvoicesProvider(partnerId));
    final paymentsAsync = ref.watch(supplierPaymentsProvider(partnerId));

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        partnerAsync.when(
          loading: () => const LoadingView(),
          error: (error, _) => const SizedBox.shrink(),
          data: (partner) {
            if (partner.balanceTiyn == null) return const SizedBox.shrink();
            final balance = partner.balanceTiyn!;
            final isDebt = balance > 0;
            return GlassCard(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isDebt
                        ? strings.purchasesOutstandingBalanceLabel
                        : strings.purchasesAdvanceBalanceLabel,
                    style: textTheme.bodyMedium,
                  ),
                  Text(
                    '${(balance.abs() / 100).toStringAsFixed(0)} ₸',
                    style: textTheme.titleMedium?.copyWith(
                      color: isDebt ? AppColors.danger : AppColors.success,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        if (canPay)
          AppButton(
            label: strings.purchasesRecordPaymentAction,
            icon: LucideIcons.banknote,
            onPressed: () async {
              final done = await RecordSupplierPaymentSheet.open(
                context,
                partnerId: partnerId,
              );
              if (done == true) {
                ref.invalidate(supplierPaymentsProvider(partnerId));
                ref.invalidate(supplierInvoicesProvider(partnerId));
                ref.invalidate(partnerDetailProvider(partnerId));
                ref.invalidate(supplierBalanceProvider(partnerId));
              }
            },
          ),
        const SizedBox(height: AppSpacing.lg),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                strings.purchasesInvoicesTitle,
                style: textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              invoicesAsync.when(
                loading: () => const LoadingView(),
                error: (error, _) => Text(strings.purchasesLoadError),
                data: (invoices) {
                  if (invoices.isEmpty) {
                    return Text(
                      strings.purchasesNoInvoices,
                      style: textTheme.bodyMedium,
                    );
                  }
                  return Column(
                    children: [
                      for (final invoice in invoices)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          invoice.invoiceNumber,
                                          style: textTheme.bodyMedium,
                                        ),
                                        Text(
                                          invoice.status ==
                                                  SupplierInvoiceStatus.paid
                                              ? strings
                                                    .purchasesInvoiceStatusPaid
                                              : invoice.status ==
                                                    SupplierInvoiceStatus
                                                        .partial
                                              ? strings
                                                    .purchasesInvoiceStatusPartial
                                              : strings
                                                    .purchasesInvoiceStatusUnpaid,
                                          style: textTheme.bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '${(invoice.paidAmountTiyn / 100).toStringAsFixed(0)} / '
                                    '${(invoice.amountTiyn / 100).toStringAsFixed(0)} ₸',
                                    style: textTheme.bodySmall,
                                  ),
                                ],
                              ),
                              if (invoice.status != SupplierInvoiceStatus.paid)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    top: AppSpacing.xs,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '${strings.purchasesOutstandingBalanceLabel}: '
                                        '${((invoice.amountTiyn - invoice.paidAmountTiyn) / 100).toStringAsFixed(0)} ₸',
                                        style: textTheme.bodySmall?.copyWith(
                                          color: AppColors.danger,
                                        ),
                                      ),
                                      if (canPay)
                                        TextButton(
                                          onPressed: () => _payInvoice(
                                            context,
                                            ref,
                                            invoice,
                                          ),
                                          child: Text(
                                            strings.purchasesPayInvoiceAction,
                                          ),
                                        ),
                                    ],
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
        ),
        const SizedBox(height: AppSpacing.lg),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                strings.purchasesPaymentsTitle,
                style: textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              paymentsAsync.when(
                loading: () => const LoadingView(),
                error: (error, _) => Text(strings.purchasesLoadError),
                data: (payments) {
                  if (payments.isEmpty) {
                    return Text(
                      strings.purchasesNoPayments,
                      style: textTheme.bodyMedium,
                    );
                  }
                  return Column(
                    children: [
                      for (final payment in payments)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: Row(
                            children: [
                              Icon(
                                payment.isReversed
                                    ? LucideIcons.rotateCcw
                                    : LucideIcons.banknote,
                                size: 16,
                                color: payment.isReversed
                                    ? AppColors.textSecondaryLight
                                    : AppColors.success,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${(payment.amountTiyn / 100).toStringAsFixed(0)} ₸',
                                      style: textTheme.bodyMedium?.copyWith(
                                        decoration: payment.isReversed
                                            ? TextDecoration.lineThrough
                                            : null,
                                      ),
                                    ),
                                    if (payment.invoiceNumber != null)
                                      Text(
                                        payment.invoiceNumber!,
                                        style: textTheme.bodySmall,
                                      ),
                                  ],
                                ),
                              ),
                              if (canPay && !payment.isReversed)
                                TextButton(
                                  onPressed: () =>
                                      _reverse(context, ref, payment.id),
                                  child: Text(
                                    strings.purchasesReversePaymentAction,
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
        ),
      ],
    );
  }
}
