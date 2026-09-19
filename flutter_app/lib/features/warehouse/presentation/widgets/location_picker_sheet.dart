import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/i18n/locale_provider.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/state_views.dart';
import '../../domain/entities/warehouse_location.dart';
import '../providers/warehouse_providers.dart';

/// Backs every location field in the receive/reserve/hold forms.
class LocationPickerSheet extends ConsumerWidget {
  const LocationPickerSheet({super.key, this.currentLocationId});

  final String? currentLocationId;

  static Future<WarehouseLocation?> open(
    BuildContext context, {
    String? currentLocationId,
  }) {
    return showAppBottomSheet<WarehouseLocation>(
      context: context,
      child: LocationPickerSheet(currentLocationId: currentLocationId),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final locationsAsync = ref.watch(warehouseLocationsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          strings.warehouseSelectLocationTitle,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.lg),
        locationsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
            child: LoadingView(),
          ),
          error: (error, _) => Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
            child: Text(strings.warehouseLoadError),
          ),
          data: (locations) {
            if (locations.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                child: Text(strings.commonEmpty),
              );
            }
            return Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final location in locations)
                    ListTile(
                      onTap: () => Navigator.of(context).pop(location),
                      leading: const Icon(LucideIcons.warehouse),
                      trailing: location.id == currentLocationId
                          ? const Icon(LucideIcons.check, size: 18)
                          : null,
                      title: Text(
                        location.name,
                        style: TextStyle(
                          fontWeight: location.id == currentLocationId
                              ? FontWeight.w700
                              : null,
                        ),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
