import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/i18n/locale_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/inventory_hold.dart';
import '../providers/warehouse_providers.dart';

/// Requirement: "Резерв" — active, non-order holds for one material.
class HoldsSection extends ConsumerWidget {
  const HoldsSection({
    super.key,
    required this.materialId,
    required this.holds,
  });

  final String materialId;
  final List<InventoryHold> holds;

  Future<void> _release(
    BuildContext context,
    WidgetRef ref,
    InventoryHold hold,
  ) async {
    final strings = ref.read(appStringsProvider);
    final result = await ref.read(releaseHoldUseCaseProvider).call(hold.id);
    if (!context.mounted) return;
    result.match(
      (failure) => AppToast.show(failure.message, tone: ToastTone.error),
      (_) {
        AppToast.show(
          strings.warehouseHoldReleasedToast,
          tone: ToastTone.success,
        );
        ref.invalidate(materialActiveHoldsProvider(materialId));
        ref.invalidate(materialsListProvider);
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final textTheme = Theme.of(context).textTheme;
    final canManage =
        ref.watch(currentUserProvider)?.canManageWarehouse ?? false;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(strings.warehouseHoldsTitle, style: textTheme.titleMedium),
          const SizedBox(height: AppSpacing.md),
          if (holds.isEmpty)
            Text(strings.warehouseNoHolds, style: textTheme.bodyMedium)
          else
            for (final hold in holds)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Row(
                  children: [
                    const Icon(
                      LucideIcons.shieldAlert,
                      size: 16,
                      color: AppColors.warning,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${hold.quantity} · ${hold.locationName ?? ''}',
                            style: textTheme.bodyMedium,
                          ),
                          if (hold.reason != null)
                            Text(hold.reason!, style: textTheme.bodySmall),
                        ],
                      ),
                    ),
                    if (canManage)
                      TextButton(
                        onPressed: () => _release(context, ref, hold),
                        child: Text(strings.warehouseReleaseHoldAction),
                      ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}
