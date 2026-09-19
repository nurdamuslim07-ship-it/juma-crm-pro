import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/i18n/locale_provider.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/state_views.dart';
import '../providers/warehouse_providers.dart';

/// Requirement: "Қойма аналитикасы" — backed by `get_warehouse_summary()`.
class WarehouseSummarySheet extends ConsumerWidget {
  const WarehouseSummarySheet({super.key});

  static Future<void> open(BuildContext context) {
    return showAppBottomSheet(
      context: context,
      child: const WarehouseSummarySheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final textTheme = Theme.of(context).textTheme;
    final summaryAsync = ref.watch(warehouseSummaryProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(strings.warehouseSummaryTitle, style: textTheme.titleLarge),
        const SizedBox(height: AppSpacing.lg),
        summaryAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
            child: LoadingView(),
          ),
          error: (error, _) => Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
            child: Text(strings.warehouseLoadError),
          ),
          data: (summary) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _row(
                context,
                strings.warehouseMaterialsCountLabel,
                '${summary.materialsCount}',
              ),
              _row(
                context,
                strings.warehouseLowStockCountLabel,
                '${summary.lowStockCount}',
              ),
              _row(
                context,
                strings.warehouseTotalValueLabel,
                '${(summary.totalInventoryValueTiyn / 100).toStringAsFixed(0)} ₸',
              ),
              if (summary.categoryBreakdown.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                for (final entry in summary.categoryBreakdown.entries)
                  _row(context, entry.key, '${entry.value}'),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _row(BuildContext context, String label, String value) {
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
