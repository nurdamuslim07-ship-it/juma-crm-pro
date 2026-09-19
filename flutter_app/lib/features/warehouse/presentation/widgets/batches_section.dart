import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/i18n/locale_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../domain/entities/inventory_batch.dart';

/// Requirement: "Партиялар" — FIFO-consumed lots, newest first.
class BatchesSection extends ConsumerWidget {
  const BatchesSection({super.key, required this.batches});

  final List<InventoryBatch> batches;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final textTheme = Theme.of(context).textTheme;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(strings.warehouseBatchesTitle, style: textTheme.titleMedium),
          const SizedBox(height: AppSpacing.md),
          if (batches.isEmpty)
            Text(strings.warehouseNoBatches, style: textTheme.bodyMedium)
          else
            for (final batch in batches)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Row(
                  children: [
                    const Icon(
                      LucideIcons.boxes,
                      size: 16,
                      color: AppColors.textSecondaryLight,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        batch.batchNumber ?? batch.locationName ?? '—',
                        style: textTheme.bodyMedium,
                      ),
                    ),
                    Text(
                      '${batch.quantityRemaining.toStringAsFixed(0)}/'
                      '${batch.quantityReceived.toStringAsFixed(0)} '
                      '${strings.warehouseBatchRemainingLabel}',
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}
