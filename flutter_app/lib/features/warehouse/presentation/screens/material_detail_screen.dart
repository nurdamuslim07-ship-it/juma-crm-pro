import '../../../../core/widgets/app_back_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/i18n/locale_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/launchers.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/material_stock.dart';
import '../providers/issue_cart_provider.dart';
import '../providers/warehouse_providers.dart';
import '../widgets/add_to_cart_sheet.dart';
import '../widgets/batches_section.dart';
import '../widgets/hold_material_sheet.dart';
import '../widgets/holds_section.dart';
import '../widgets/receive_material_sheet.dart';
import '../widgets/reserve_material_sheet.dart';

/// Requirement: material detail — stock breakdown, barcode, preferred
/// supplier contact ("Жеткізушімен байланыс"), batches ("Партиялар"),
/// active holds ("Резерв"), and the receive/reserve/hold/cart actions.
class MaterialDetailScreen extends ConsumerWidget {
  const MaterialDetailScreen({super.key, required this.materialId});
  final String materialId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final materialAsync = ref.watch(materialByIdProvider(materialId));

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: Text(strings.warehouseMaterialDetailTitle),
      ),
      body: materialAsync.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorView(
          message: strings.warehouseLoadError,
          retryLabel: strings.commonRetry,
          onRetry: () => ref.invalidate(materialByIdProvider(materialId)),
        ),
        data: (material) {
          if (material == null) {
            return EmptyView(
              icon: LucideIcons.packageOpen,
              title: strings.warehouseEmptyTitle,
            );
          }
          return _DetailBody(material: material);
        },
      ),
    );
  }
}

class _DetailBody extends ConsumerWidget {
  const _DetailBody({required this.material});
  final MaterialStock material;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final textTheme = Theme.of(context).textTheme;
    final canManage =
        ref.watch(currentUserProvider)?.canManageWarehouse ?? false;
    final batchesAsync = ref.watch(
      materialBatchesProvider(material.materialId),
    );
    final holdsAsync = ref.watch(
      materialActiveHoldsProvider(material.materialId),
    );

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
                        Text(material.name, style: textTheme.titleLarge),
                        if (material.categoryNameKk != null)
                          Text(
                            material.categoryNameKk!,
                            style: textTheme.bodyMedium,
                          ),
                      ],
                    ),
                  ),
                  if (material.isLowStock)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        strings.warehouseLowStockBadge,
                        style: const TextStyle(
                          color: AppColors.danger,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              _statRow(
                context,
                strings.warehouseAvailableLabel,
                '${material.availableQuantity.toStringAsFixed(0)} ${material.unit}',
              ),
              _statRow(
                context,
                strings.warehouseReservedLabel,
                '${material.totalReserved.toStringAsFixed(0)} ${material.unit}',
              ),
              _statRow(
                context,
                strings.warehouseMinQuantityLabel,
                '${material.minQuantity.toStringAsFixed(0)} ${material.unit}',
              ),
              _statRow(
                context,
                strings.warehouseBarcodeLabel,
                material.barcode ?? strings.warehouseNoBarcode,
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
                strings.warehousePreferredSupplierLabel,
                style: textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                material.preferredPartnerName ?? strings.warehouseNoSupplier,
                style: textTheme.bodyMedium,
              ),
              if (material.preferredPartnerPhone != null ||
                  material.preferredPartnerWhatsapp != null) ...[
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    if (material.preferredPartnerPhone != null)
                      Expanded(
                        child: AppButton(
                          label: strings.warehouseCallAction,
                          icon: LucideIcons.phone,
                          variant: AppButtonVariant.secondary,
                          onPressed: () async {
                            final ok = await AppLaunchers.call(
                              material.preferredPartnerPhone!,
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
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: AppButton(
                        label: strings.warehouseWhatsappAction,
                        icon: LucideIcons.messageCircle,
                        variant: AppButtonVariant.secondary,
                        onPressed: () async {
                          final ok = await AppLaunchers.whatsapp(
                            material.preferredPartnerWhatsapp ??
                                material.preferredPartnerPhone!,
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
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        batchesAsync.when(
          loading: () => const LoadingView(),
          error: (error, _) => const SizedBox.shrink(),
          data: (batches) => BatchesSection(batches: batches),
        ),
        const SizedBox(height: AppSpacing.lg),
        holdsAsync.when(
          loading: () => const LoadingView(),
          error: (error, _) => const SizedBox.shrink(),
          data: (holds) =>
              HoldsSection(materialId: material.materialId, holds: holds),
        ),
        const SizedBox(height: AppSpacing.xl),
        if (canManage) ...[
          AppButton(
            label: strings.warehouseReceiveAction,
            icon: LucideIcons.packageOpen,
            onPressed: () async {
              final done = await ReceiveMaterialSheet.open(context, material);
              if (done == true) {
                ref.invalidate(materialByIdProvider(material.materialId));
                ref.invalidate(materialBatchesProvider(material.materialId));
                ref.invalidate(materialsListProvider);
              }
            },
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: strings.warehouseReserveAction,
                  icon: LucideIcons.lock,
                  variant: AppButtonVariant.secondary,
                  onPressed: () async {
                    final done = await ReserveMaterialSheet.open(
                      context,
                      material,
                    );
                    if (done == true) {
                      ref.invalidate(materialByIdProvider(material.materialId));
                      ref.invalidate(materialsListProvider);
                    }
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: AppButton(
                  label: strings.warehouseHoldAction,
                  icon: LucideIcons.shieldAlert,
                  variant: AppButtonVariant.secondary,
                  onPressed: () async {
                    final done = await HoldMaterialSheet.open(
                      context,
                      material,
                    );
                    if (done == true) {
                      ref.invalidate(materialByIdProvider(material.materialId));
                      ref.invalidate(
                        materialActiveHoldsProvider(material.materialId),
                      );
                      ref.invalidate(materialsListProvider);
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: strings.warehouseAddToCartAction,
            icon: LucideIcons.shoppingCart,
            variant: AppButtonVariant.secondary,
            onPressed: () async {
              final item = await AddToCartSheet.open(context, material);
              if (item != null) {
                ref.read(issueCartProvider.notifier).add(item);
              }
            },
          ),
        ],
      ],
    );
  }

  Widget _statRow(BuildContext context, String label, String value) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: textTheme.bodyMedium),
          Text(
            value,
            style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
