import '../../../../core/widgets/press_motion.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../domain/entities/material_stock.dart';

/// Requirement: "Планшет ... Table" — stock is fundamentally tabular/
/// numeric data with no discrete workflow-stage concept (unlike
/// Production's genuine Kanban board), so the tablet/desktop layout is
/// a data table rather than a literal Kanban reinterpretation.
class MaterialsTable extends StatelessWidget {
  const MaterialsTable({
    super.key,
    required this.materials,
    required this.onRowTap,
    required this.columnMaterial,
    required this.columnCategory,
    required this.columnAvailable,
    required this.columnReserved,
    required this.columnMin,
  });

  final List<MaterialStock> materials;
  final ValueChanged<MaterialStock> onRowTap;
  final String columnMaterial;
  final String columnCategory;
  final String columnAvailable;
  final String columnReserved;
  final String columnMin;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final headerStyle = textTheme.bodySmall?.copyWith(
      fontWeight: FontWeight.w700,
      color: AppColors.textSecondaryLight,
    );

    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(columnMaterial, style: headerStyle),
              ),
              Expanded(
                flex: 2,
                child: Text(columnCategory, style: headerStyle),
              ),
              Expanded(
                child: Text(
                  columnAvailable,
                  style: headerStyle,
                  textAlign: TextAlign.right,
                ),
              ),
              Expanded(
                child: Text(
                  columnReserved,
                  style: headerStyle,
                  textAlign: TextAlign.right,
                ),
              ),
              Expanded(
                child: Text(
                  columnMin,
                  style: headerStyle,
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
          const Divider(height: AppSpacing.lg),
          for (final material in materials)
            MotionInkWell(
              onTap: () => onRowTap(material),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Row(
                        children: [
                          if (material.isLowStock)
                            const Padding(
                              padding: EdgeInsets.only(right: AppSpacing.xs),
                              child: Icon(
                                LucideIcons.alertTriangle,
                                size: 14,
                                color: AppColors.danger,
                              ),
                            ),
                          Expanded(
                            child: Text(
                              material.name,
                              style: textTheme.bodyMedium,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        material.categoryNameKk ?? '—',
                        style: textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '${material.availableQuantity.toStringAsFixed(0)} ${material.unit}',
                        textAlign: TextAlign.right,
                        style: textTheme.bodyMedium?.copyWith(
                          color: material.isLowStock ? AppColors.danger : null,
                          fontWeight: material.isLowStock
                              ? FontWeight.w700
                              : null,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        material.totalReserved.toStringAsFixed(0),
                        textAlign: TextAlign.right,
                        style: textTheme.bodyMedium,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        material.minQuantity.toStringAsFixed(0),
                        textAlign: TextAlign.right,
                        style: textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
