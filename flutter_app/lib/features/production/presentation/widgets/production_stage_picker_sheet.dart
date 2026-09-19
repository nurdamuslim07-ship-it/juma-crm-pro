import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/i18n/locale_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../domain/entities/production_stage.dart';
import 'production_stage_x.dart';

/// Requirement: "Өндіріс кезеңін ауыстыру" (phone's non-drag-and-drop
/// move action) and the queue's stage filter. [allowAll] shows the
/// "Барлығы" tile used by the filter; the move-stage action passes
/// `allowAll: false` since a stage is required there.
class ProductionStagePickerSheet extends ConsumerWidget {
  const ProductionStagePickerSheet({
    super.key,
    required this.stages,
    this.current,
    this.allowAll = true,
  });

  final List<ProductionStage> stages;
  final ProductionStage? current;
  final bool allowAll;

  static Future<Object?> open(
    BuildContext context, {
    required List<ProductionStage> stages,
    ProductionStage? current,
    bool allowAll = true,
  }) {
    return showAppBottomSheet<Object>(
      context: context,
      child: ProductionStagePickerSheet(
        stages: stages,
        current: current,
        allowAll: allowAll,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);

    Widget tile(String label, ProductionStage? value, {IconData? icon}) {
      return ListTile(
        onTap: () => Navigator.of(context).pop(_PickedStage(value)),
        leading: icon != null
            ? Icon(
                icon,
                color: value?.id == current?.id
                    ? AppColors.skyDeep
                    : AppColors.textSecondaryLight,
              )
            : null,
        trailing: value?.id == current?.id
            ? const Icon(LucideIcons.check, size: 18)
            : null,
        title: Text(
          label,
          style: TextStyle(
            fontWeight: value?.id == current?.id ? FontWeight.w700 : null,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          strings.productionSelectStageTitle,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.lg),
        Flexible(
          child: ListView(
            shrinkWrap: true,
            children: [
              if (allowAll) tile(strings.productionFilterAllStages, null),
              for (final stage in stages)
                tile(stage.nameKk, stage, icon: stage.icon),
            ],
          ),
        ),
      ],
    );
  }
}

class _PickedStage {
  const _PickedStage(this.value);
  final ProductionStage? value;
}

({bool picked, ProductionStage? value}) unwrapPickedStage(Object? result) {
  if (result is _PickedStage) return (picked: true, value: result.value);
  return (picked: false, value: null);
}
