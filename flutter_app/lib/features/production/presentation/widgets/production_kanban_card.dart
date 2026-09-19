import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/i18n/locale_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../domain/entities/production_queue_item.dart';

class ProductionKanbanCard extends ConsumerWidget {
  const ProductionKanbanCard({
    super.key,
    required this.item,
    this.onTap,
    this.width,
  });

  final ProductionQueueItem item;
  final VoidCallback? onTap;
  final double? width;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final textTheme = Theme.of(context).textTheme;

    return SizedBox(
      width: width,
      child: GlassCard(
        onTap: onTap,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.orderNumber,
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              item.productType,
              style: textTheme.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              item.clientName,
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondaryLight,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: LinearProgressIndicator(
                value: item.percentComplete / 100,
                minHeight: 5,
                backgroundColor: AppColors.skyDeep.withValues(alpha: 0.12),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                if (item.masterName != null) ...[
                  const Icon(
                    LucideIcons.hardHat,
                    size: 13,
                    color: AppColors.textSecondaryLight,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      item.masterName!,
                      style: textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ] else
                  Expanded(
                    child: Text(
                      strings.productionNoMasterAssigned,
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.warning,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                if (!item.materialsSufficient)
                  const Icon(
                    LucideIcons.alertTriangle,
                    size: 14,
                    color: AppColors.danger,
                  ),
                if (item.photosCount > 0) ...[
                  const SizedBox(width: 6),
                  const Icon(
                    LucideIcons.camera,
                    size: 13,
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
