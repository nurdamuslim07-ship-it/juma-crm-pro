import '../../../../core/widgets/app_back_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/i18n/app_strings.dart';
import '../../../../core/i18n/locale_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/state_views.dart';
import '../../domain/entities/purchase_analytics.dart';
import '../providers/purchases_providers.dart';

/// Requirement: "Purchase Analytics" screen — Айлық сатып алу / Ең көп
/// сатып алынған материалдар / Орташа сатып алу бағасы / Қарыз / Аванс
/// / Жеткізуші рейтингі, all from `get_purchase_analytics()`.
class PurchaseAnalyticsScreen extends ConsumerWidget {
  const PurchaseAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final analyticsAsync = ref.watch(purchaseAnalyticsProvider);

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: Text(strings.purchasesAnalyticsTitle),
      ),
      body: analyticsAsync.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorView(
          message: strings.purchasesLoadError,
          retryLabel: strings.commonRetry,
          onRetry: () => ref.invalidate(purchaseAnalyticsProvider),
        ),
        data: (analytics) {
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(purchaseAnalyticsProvider),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                GridView.count(
                  crossAxisCount: context.isMobile ? 2 : 4,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: AppSpacing.md,
                  crossAxisSpacing: AppSpacing.md,
                  childAspectRatio: 1.4,
                  children: [
                    _KpiCard(
                      label: strings.purchasesMonthlyPurchasesLabel,
                      value:
                          '${(analytics.monthlyPurchasesTiyn / 100).toStringAsFixed(0)} ₸',
                    ),
                    _KpiCard(
                      label: strings.purchasesTotalDebtLabel,
                      value:
                          '${(analytics.totalDebtTiyn / 100).toStringAsFixed(0)} ₸',
                      color: AppColors.danger,
                    ),
                    _KpiCard(
                      label: strings.purchasesTotalAdvanceLabel,
                      value:
                          '${(analytics.totalAdvanceTiyn / 100).toStringAsFixed(0)} ₸',
                      color: AppColors.success,
                    ),
                    _KpiCard(
                      label: strings.purchasesAvgUnitPriceLabel,
                      value:
                          '${(analytics.avgUnitPriceTiyn / 100).toStringAsFixed(0)} ₸',
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                if (context.isMobile) ...[
                  _TopMaterialsCard(analytics: analytics, strings: strings),
                  const SizedBox(height: AppSpacing.lg),
                  _SupplierRatingsCard(analytics: analytics, strings: strings),
                ] else
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _TopMaterialsCard(
                            analytics: analytics,
                            strings: strings,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.lg),
                        Expanded(
                          child: _SupplierRatingsCard(
                            analytics: analytics,
                            strings: strings,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Requirement: "KPI cards" — one compact card per top-level metric,
/// laid out in a 2-column grid on phone and a 4-column grid on
/// tablet/desktop/web (see [PurchaseAnalyticsScreen]'s `GridView.count`).
class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.label, required this.value, this.color});

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return GlassCard(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: textTheme.bodySmall),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _TopMaterialsCard extends StatelessWidget {
  const _TopMaterialsCard({required this.analytics, required this.strings});

  final PurchaseAnalytics analytics;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings.purchasesTopMaterialsTitle,
            style: textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          if (analytics.topMaterials.isEmpty)
            Text(strings.purchasesNoDataYet, style: textTheme.bodyMedium)
          else
            for (final material in analytics.topMaterials)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Row(
                  children: [
                    const Icon(
                      LucideIcons.boxes,
                      size: 16,
                      color: AppColors.skyDeep,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        material.materialName,
                        style: textTheme.bodyMedium,
                      ),
                    ),
                    Text(
                      material.totalQuantity.toStringAsFixed(0),
                      style: textTheme.bodySmall,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Text(
                      '${(material.totalSpentTiyn / 100).toStringAsFixed(0)} ₸',
                      style: textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

class _SupplierRatingsCard extends StatelessWidget {
  const _SupplierRatingsCard({required this.analytics, required this.strings});

  final PurchaseAnalytics analytics;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings.purchasesSupplierRatingsTitle,
            style: textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          if (analytics.supplierRatings.isEmpty)
            Text(strings.purchasesNoDataYet, style: textTheme.bodyMedium)
          else
            for (final supplier in analytics.supplierRatings)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Row(
                  children: [
                    const Icon(
                      LucideIcons.building2,
                      size: 16,
                      color: AppColors.skyDeep,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            supplier.displayName,
                            style: textTheme.bodyMedium,
                          ),
                          if (supplier.onTimeRate != null)
                            Text(
                              '${strings.purchasesOnTimeRateLabel}: '
                              '${(supplier.onTimeRate! * 100).toStringAsFixed(0)}%',
                              style: textTheme.bodySmall,
                            ),
                        ],
                      ),
                    ),
                    if (supplier.trustRating != null)
                      Row(
                        children: [
                          for (var i = 0; i < supplier.trustRating!; i++)
                            const Icon(
                              LucideIcons.star,
                              size: 12,
                              color: AppColors.warning,
                            ),
                        ],
                      ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}
