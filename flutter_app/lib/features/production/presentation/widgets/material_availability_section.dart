import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/i18n/locale_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../purchases/presentation/providers/purchases_providers.dart';
import '../../domain/entities/material_availability.dart';

/// Requirement: "Материал жеткіліктілігін көрсету" — per-material
/// reserved-vs-available breakdown, backed by
/// `get_order_production_detail()`'s `materials` field (which reads
/// through `material_reservations`/`inventory_balances` — see
/// supabase/migrations/20260713000020_production_module.sql).
class MaterialAvailabilitySection extends ConsumerWidget {
  const MaterialAvailabilitySection({super.key, required this.materials});

  final List<MaterialAvailability> materials;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final textTheme = Theme.of(context).textTheme;
    // Requirement: Purchases/Production integration — "Production
    // күтіп тұрған материалдарды көрсету". Read via valueOrNull so a
    // slow/failed fetch never blocks this section's own data; the
    // badge is purely an extra annotation, not load-bearing.
    final pendingQuantities = ref
        .watch(pendingPurchaseQuantitiesProvider)
        .valueOrNull;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(strings.productionMaterialsTitle, style: textTheme.titleMedium),
          const SizedBox(height: AppSpacing.md),
          if (materials.isEmpty)
            Text(
              strings.productionNoMaterialsReserved,
              style: textTheme.bodyMedium,
            )
          else
            for (final material in materials)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Row(
                  children: [
                    Icon(
                      material.isSufficient
                          ? LucideIcons.checkCircle2
                          : LucideIcons.alertTriangle,
                      size: 16,
                      color: material.isSufficient
                          ? AppColors.success
                          : AppColors.danger,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            material.materialName,
                            style: textTheme.bodyMedium,
                          ),
                          if (!material.isSufficient &&
                              material.materialId != null &&
                              (pendingQuantities?[material.materialId!] ?? 0) >
                                  0)
                            Text(
                              '${strings.purchasesPendingBadge}: '
                              '${pendingQuantities![material.materialId!]!.toStringAsFixed(0)} '
                              '${material.unit}',
                              style: textTheme.bodySmall?.copyWith(
                                color: AppColors.skyDeep,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Text(
                      '${material.reservedQuantity.toStringAsFixed(0)}/'
                      '${material.availableQuantity.toStringAsFixed(0)} '
                      '${material.unit}',
                      style: textTheme.bodySmall?.copyWith(
                        color: material.isSufficient
                            ? AppColors.textSecondaryLight
                            : AppColors.danger,
                        fontWeight: material.isSufficient
                            ? null
                            : FontWeight.w700,
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
