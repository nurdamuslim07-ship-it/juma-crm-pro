import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/i18n/locale_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';

/// "Сенімділік рейтингі" — a 1-5 star rating, optional (`null` =
/// "белгіленбеген").
class PartnerTrustRatingPickerSheet extends ConsumerWidget {
  const PartnerTrustRatingPickerSheet({super.key, this.current});

  final int? current;

  static Future<Object?> open(BuildContext context, {int? current}) {
    return showAppBottomSheet<Object>(
      context: context,
      child: PartnerTrustRatingPickerSheet(current: current),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);

    Widget tile(String label, int? value) {
      return ListTile(
        onTap: () => Navigator.of(context).pop(_PickedRating(value)),
        leading: value != null
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  value,
                  (_) => const Icon(
                    LucideIcons.star,
                    size: 16,
                    color: AppColors.warning,
                  ),
                ),
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
          strings.partnerFormTrustRatingLabel,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.lg),
        tile(strings.partnerTrustRatingUnset, null),
        for (var i = 1; i <= 5; i++) tile('$i', i),
      ],
    );
  }
}

class _PickedRating {
  const _PickedRating(this.value);
  final int? value;
}

({bool picked, int? value}) unwrapPickedRating(Object? result) {
  if (result is _PickedRating) return (picked: true, value: result.value);
  return (picked: false, value: null);
}
