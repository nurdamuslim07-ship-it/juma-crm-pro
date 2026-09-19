import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../domain/entities/material_stock.dart';

/// Requirement: "Телефон/List" — the phone view of one material row.
class MaterialListTile extends StatelessWidget {
  const MaterialListTile({super.key, required this.material, this.onTap});

  final MaterialStock material;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: GlassCard(
        onTap: onTap,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Icon(
              LucideIcons.boxes,
              color: material.isLowStock ? AppColors.danger : AppColors.skyDeep,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    material.name,
                    style: textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (material.categoryNameKk != null)
                    Text(material.categoryNameKk!, style: textTheme.bodySmall),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${material.availableQuantity.toStringAsFixed(0)} ${material.unit}',
                  style: textTheme.bodyLarge?.copyWith(
                    color: material.isLowStock ? AppColors.danger : null,
                    fontWeight: material.isLowStock ? FontWeight.w700 : null,
                  ),
                ),
                if (material.isLowStock)
                  const Icon(
                    LucideIcons.alertTriangle,
                    size: 14,
                    color: AppColors.danger,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
