import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/i18n/locale_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../domain/entities/production_queue_item.dart';

class ProductionQueueTile extends ConsumerWidget {
  const ProductionQueueTile({
    super.key,
    required this.item,
    required this.onTap,
  });

  final ProductionQueueItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: GlassCard(
        onTap: onTap,
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(item.orderNumber, style: textTheme.titleMedium),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.skyDeep.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    item.stageNameKk,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.skyDeep,
                    ),
                  ),
                ),
              ],
            ),
            Text(
              '${item.productType} · ${item.clientName}',
              style: textTheme.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: LinearProgressIndicator(
                value: item.percentComplete / 100,
                minHeight: 6,
                backgroundColor: AppColors.skyDeep.withValues(alpha: 0.12),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Icon(
                  LucideIcons.hardHat,
                  size: 14,
                  color: item.masterName != null
                      ? AppColors.textSecondaryLight
                      : AppColors.warning,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    item.masterName ?? strings.productionNoMasterAssigned,
                    style: textTheme.bodySmall?.copyWith(
                      color: item.masterName != null
                          ? AppColors.textSecondaryLight
                          : AppColors.warning,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (!item.materialsSufficient)
                  const Icon(
                    LucideIcons.alertTriangle,
                    size: 15,
                    color: AppColors.danger,
                  ),
                if (item.photosCount > 0) ...[
                  const SizedBox(width: AppSpacing.sm),
                  const Icon(
                    LucideIcons.camera,
                    size: 14,
                    color: AppColors.textSecondaryLight,
                  ),
                  Text('${item.photosCount}', style: textTheme.bodySmall),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
