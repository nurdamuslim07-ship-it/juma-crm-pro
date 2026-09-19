import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/i18n/locale_provider.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';

/// Requirement #9 "белсенді/белсенді емес статус бойынша фильтр" —
/// `null` means "барлық статустар" (both).
class EmployeeStatusPickerSheet extends ConsumerWidget {
  const EmployeeStatusPickerSheet({super.key, this.current});

  final bool? current;

  static Future<Object?> open(BuildContext context, {bool? current}) {
    return showAppBottomSheet<Object>(
      context: context,
      child: EmployeeStatusPickerSheet(current: current),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);

    Widget tile(String label, bool? value) {
      return ListTile(
        // `showAppBottomSheet<Object>` + a sentinel lets us
        // distinguish "picked null" (all statuses) from "dismissed"
        // (also null) at the call site.
        onTap: () => Navigator.of(context).pop(_PickedStatus(value)),
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
          strings.employeeFormStatusLabel,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.lg),
        tile(strings.employeeFilterAllStatuses, null),
        tile(strings.employeeFilterActive, true),
        tile(strings.employeeFilterInactive, false),
      ],
    );
  }
}

class _PickedStatus {
  const _PickedStatus(this.value);
  final bool? value;
}

/// Unwraps the sentinel — returns `(picked: true, value: ...)` or
/// `(picked: false, value: null)` if the sheet was dismissed.
({bool picked, bool? value}) unwrapPickedStatus(Object? result) {
  if (result is _PickedStatus) return (picked: true, value: result.value);
  return (picked: false, value: null);
}
