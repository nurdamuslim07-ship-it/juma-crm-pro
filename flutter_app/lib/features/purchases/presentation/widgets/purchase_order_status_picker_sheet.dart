import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/i18n/locale_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../domain/entities/purchase_order_status.dart';
import 'purchase_order_status_x.dart';

/// Requirement: "Status Picker" — backs both the list screen's status
/// filter ([allowAll] true) and any future explicit status-set action.
class PurchaseOrderStatusPickerSheet extends ConsumerWidget {
  const PurchaseOrderStatusPickerSheet({
    super.key,
    this.current,
    this.allowAll = true,
  });

  final PurchaseOrderStatus? current;
  final bool allowAll;

  static Future<Object?> open(
    BuildContext context, {
    PurchaseOrderStatus? current,
    bool allowAll = true,
  }) {
    return showAppBottomSheet<Object>(
      context: context,
      child: PurchaseOrderStatusPickerSheet(
        current: current,
        allowAll: allowAll,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);

    Widget tile(String label, PurchaseOrderStatus? value) {
      return ListTile(
        onTap: () => Navigator.of(context).pop(_PickedStatus(value)),
        leading: value != null
            ? Icon(
                value.icon,
                color: value == current
                    ? AppColors.skyDeep
                    : AppColors.textSecondaryLight,
              )
            : null,
        trailing: value == current
            ? const Icon(LucideIcons.check, size: 18)
            : null,
        title: Text(
          label,
          style: TextStyle(
            fontWeight: value == current ? FontWeight.w700 : null,
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
          strings.purchasesSelectStatusTitle,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.lg),
        Flexible(
          child: ListView(
            shrinkWrap: true,
            children: [
              if (allowAll) tile(strings.purchasesFilterAllStatuses, null),
              for (final status in PurchaseOrderStatus.values)
                tile(status.nameKk(strings), status),
            ],
          ),
        ),
      ],
    );
  }
}

class _PickedStatus {
  const _PickedStatus(this.value);
  final PurchaseOrderStatus? value;
}

({bool picked, PurchaseOrderStatus? value}) unwrapPickedPurchaseOrderStatus(
  Object? result,
) {
  if (result is _PickedStatus) return (picked: true, value: result.value);
  return (picked: false, value: null);
}
