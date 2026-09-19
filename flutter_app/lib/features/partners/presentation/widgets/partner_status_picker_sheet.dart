import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/i18n/locale_provider.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';

/// Requirement #9 "белсенді/белсенді емес бойынша фильтр" — `null`
/// means "барлық статустар" (both).
class PartnerStatusPickerSheet extends ConsumerWidget {
  const PartnerStatusPickerSheet({super.key, this.current});

  final bool? current;

  static Future<Object?> open(BuildContext context, {bool? current}) {
    return showAppBottomSheet<Object>(
      context: context,
      child: PartnerStatusPickerSheet(current: current),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);

    Widget tile(String label, bool? value) {
      return ListTile(
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
          strings.partnerFormStatusLabel,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.lg),
        tile(strings.partnerFilterAllStatuses, null),
        tile(strings.partnerFilterActive, true),
        tile(strings.partnerFilterInactive, false),
      ],
    );
  }
}

class _PickedStatus {
  const _PickedStatus(this.value);
  final bool? value;
}

({bool picked, bool? value}) unwrapPartnerPickedStatus(Object? result) {
  if (result is _PickedStatus) return (picked: true, value: result.value);
  return (picked: false, value: null);
}
