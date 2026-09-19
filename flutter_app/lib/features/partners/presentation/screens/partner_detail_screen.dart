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
import '../../../../core/utils/launchers.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../purchases/presentation/providers/purchases_providers.dart';
import '../../../purchases/presentation/screens/supplier_payments_screen.dart';
import '../../../purchases/presentation/widgets/purchase_history_section.dart';
import '../../domain/entities/partner.dart';
import '../providers/partner_providers.dart';
import '../widgets/partner_category_x.dart';
import '../widgets/partner_document_list.dart';

class PartnerDetailScreen extends ConsumerWidget {
  const PartnerDetailScreen({super.key, required this.partnerId});
  final String partnerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final partnerAsync = ref.watch(partnerDetailProvider(partnerId));

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: Text(strings.navPartners),
      ),
      body: partnerAsync.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorView(
          message: strings.partnerNotFound,
          retryLabel: strings.commonRetry,
          onRetry: () => ref.invalidate(partnerDetailProvider(partnerId)),
        ),
        data: (partner) => _PartnerDetailBody(partner: partner),
      ),
    );
  }
}

class _PartnerDetailBody extends ConsumerWidget {
  const _PartnerDetailBody({required this.partner});
  final Partner partner;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final textTheme = Theme.of(context).textTheme;
    final currentUser = ref.watch(currentUserProvider);
    final canWrite = currentUser?.canWritePartners ?? false;
    final canDelete = currentUser?.canDeletePartners ?? false;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.skyDeep.withValues(alpha: 0.15),
                    child: Icon(
                      partner.category.icon,
                      color: AppColors.skyDeep,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(partner.displayName, style: textTheme.titleLarge),
                        Text(
                          partner.category.label(strings),
                          style: textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  if (!partner.isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.textSecondaryLight.withValues(
                          alpha: 0.15,
                        ),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        strings.partnerStatusInactive,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              if (partner.phone != null || partner.whatsappPhone != null) ...[
                const SizedBox(height: AppSpacing.xl),
                Row(
                  children: [
                    if (partner.phone != null)
                      Expanded(
                        child: AppButton(
                          label: strings.partnerCallAction,
                          icon: LucideIcons.phone,
                          variant: AppButtonVariant.secondary,
                          onPressed: () async {
                            final ok = await AppLaunchers.call(partner.phone!);
                            if (!ok && context.mounted) {
                              AppToast.show(
                                strings.commonCannotOpenLink,
                                tone: ToastTone.error,
                              );
                            }
                          },
                        ),
                      ),
                    if (partner.phone != null && partner.whatsappPhone != null)
                      const SizedBox(width: AppSpacing.md),
                    if (partner.whatsappPhone != null || partner.phone != null)
                      Expanded(
                        child: AppButton(
                          label: strings.partnerWhatsappAction,
                          icon: LucideIcons.messageCircle,
                          variant: AppButtonVariant.secondary,
                          onPressed: () async {
                            final ok = await AppLaunchers.whatsapp(
                              partner.whatsappPhone ?? partner.phone!,
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
              if (partner.address != null) ...[
                const SizedBox(height: AppSpacing.md),
                AppButton(
                  label: strings.partnerOpenMapAction,
                  icon: LucideIcons.mapPin,
                  variant: AppButtonVariant.secondary,
                  onPressed: () async {
                    final ok = await AppLaunchers.openAddressOnMap(
                      partner.address!,
                    );
                    if (!ok && context.mounted) {
                      AppToast.show(
                        strings.commonCannotOpenLink,
                        tone: ToastTone.error,
                      );
                    }
                  },
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _InfoRow(
                icon: LucideIcons.building2,
                label: strings.partnerFormCompanyNameLabel,
                value: partner.companyName,
              ),
              _InfoRow(
                icon: LucideIcons.phone,
                label: strings.partnerFormPhoneSecondaryLabel,
                value: partner.phoneSecondary,
              ),
              _InfoRow(
                icon: LucideIcons.user,
                label: strings.partnerFormContactPersonLabel,
                value: partner.contactPerson,
              ),
              _InfoRow(
                icon: LucideIcons.mapPin,
                label: strings.partnerFormAddressLabel,
                value: partner.city != null
                    ? '${partner.city}, ${partner.address ?? ''}'
                    : partner.address,
              ),
              _InfoRow(
                icon: LucideIcons.stickyNote,
                label: strings.partnerFormNotesLabel,
                value: partner.notes,
                isLast:
                    !partner.hasExtendedAccess && !partner.hasFinancialAccess,
              ),
              if (partner.hasExtendedAccess) ...[
                _InfoRow(
                  icon: LucideIcons.badge,
                  label: strings.partnerFormTaxIdLabel,
                  value: partner.taxId,
                ),
                _InfoRow(
                  icon: LucideIcons.package,
                  label: strings.partnerFormServiceDescriptionLabel,
                  value: partner.serviceDescription,
                ),
                _InfoRow(
                  icon: LucideIcons.tag,
                  label: strings.partnerFormPriceNoteLabel,
                  value: partner.priceNote,
                ),
                _InfoRow(
                  icon: LucideIcons.star,
                  label: strings.partnerFormTrustRatingLabel,
                  value: partner.trustRating != null
                      ? '${partner.trustRating}/5'
                      : null,
                ),
                _InfoRow(
                  icon: LucideIcons.calendarClock,
                  label: strings.partnerFormLastWorkedAtLabel,
                  value: partner.lastWorkedAt != null
                      ? AppFormatters.date(partner.lastWorkedAt!)
                      : null,
                  isLast: !partner.hasFinancialAccess,
                ),
              ],
              if (partner.hasFinancialAccess) ...[
                _InfoRow(
                  icon: LucideIcons.creditCard,
                  label: strings.partnerFormBankDetailsLabel,
                  value: partner.bankDetails,
                ),
                _InfoRow(
                  icon: LucideIcons.wallet,
                  label: strings.partnerFormBalanceLabel,
                  value: AppFormatters.tenge(partner.balanceTiyn ?? 0),
                  isLast: true,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (partner.hasExtendedAccess)
          PartnerDocumentList(partnerId: partner.id, canWrite: canWrite),
        if (currentUser?.canReadPurchases ?? false) ...[
          const SizedBox(height: AppSpacing.lg),
          PurchaseHistorySection(partnerId: partner.id),
          const SizedBox(height: AppSpacing.lg),
          SupplierPaymentsSection(partnerId: partner.id),
        ],
        const SizedBox(height: AppSpacing.xl),
        if (canWrite && !partner.isDeleted) ...[
          AppButton(
            label: strings.commonEdit,
            icon: LucideIcons.pencil,
            variant: AppButtonVariant.secondary,
            onPressed: () async {
              final updated = await context.push<bool>(
                RoutePaths.partnerEdit(partner.id),
                extra: partner,
              );
              if (updated == true) {
                ref.invalidate(partnerDetailProvider(partner.id));
              }
            },
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        if (partner.hasFinancialAccess && !partner.isDeleted) ...[
          AppButton(
            label: strings.partnerEditFinancialsAction,
            icon: LucideIcons.banknote,
            variant: AppButtonVariant.secondary,
            onPressed: () => _editFinancials(context, ref, partner, strings),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        if (canDelete && !partner.isDeleted)
          AppButton(
            label: strings.commonDelete,
            icon: LucideIcons.trash2,
            variant: AppButtonVariant.destructive,
            onPressed: () => _confirmDelete(context, ref, partner, strings),
          ),
        if (canDelete && partner.isDeleted)
          AppButton(
            label: strings.partnerRestoreAction,
            icon: LucideIcons.undo2,
            onPressed: () async {
              final result = await ref
                  .read(restorePartnerUseCaseProvider)
                  .call(partner.id);
              if (!context.mounted) return;
              result.match(
                (failure) =>
                    AppToast.show(failure.message, tone: ToastTone.error),
                (_) {
                  AppToast.show(
                    strings.partnerRestoredToast,
                    tone: ToastTone.success,
                  );
                  ref.invalidate(partnerDetailProvider(partner.id));
                },
              );
            },
          ),
      ],
    );
  }

  Future<void> _editFinancials(
    BuildContext context,
    WidgetRef ref,
    Partner partner,
    dynamic strings,
  ) async {
    final controller = TextEditingController(text: partner.bankDetails);
    final balanceController = TextEditingController(
      text: ((partner.balanceTiyn ?? 0) / 100).toStringAsFixed(0),
    );
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.partnerEditFinancialsAction),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: strings.partnerFormBankDetailsLabel,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: balanceController,
              keyboardType: const TextInputType.numberWithOptions(signed: true),
              decoration: InputDecoration(
                labelText: strings.partnerFormBalanceLabel,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(strings.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(strings.commonSave),
          ),
        ],
      ),
    );

    if (saved != true || !context.mounted) return;

    final balanceTiyn = ((num.tryParse(balanceController.text) ?? 0) * 100)
        .round();
    final result = await ref
        .read(updatePartnerFinancialsUseCaseProvider)
        .call(
          id: partner.id,
          bankDetails: controller.text.trim().isEmpty
              ? null
              : controller.text.trim(),
          balanceTiyn: balanceTiyn,
        );

    if (!context.mounted) return;
    result.match(
      (failure) => AppToast.show(failure.message, tone: ToastTone.error),
      (_) {
        AppToast.show(strings.partnerUpdatedToast, tone: ToastTone.success);
        ref.invalidate(partnerDetailProvider(partner.id));
      },
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Partner partner,
    dynamic strings,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.partnerDeleteConfirmTitle),
        content: Text(strings.partnerDeleteConfirmBody),
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

    final result = await ref
        .read(deletePartnerUseCaseProvider)
        .call(partner.id);
    if (!context.mounted) return;

    result.match(
      (failure) => AppToast.show(failure.message, tone: ToastTone.error),
      (_) {
        AppToast.show(strings.partnerDeletedToast, tone: ToastTone.success);
        context.pop();
      },
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
  final String? value;
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
                Text(
                  value?.isNotEmpty == true ? value! : '—',
                  style: textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
