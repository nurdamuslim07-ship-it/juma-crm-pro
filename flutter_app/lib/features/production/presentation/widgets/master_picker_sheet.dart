import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/i18n/locale_provider.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/state_views.dart';
import '../../domain/entities/production_master.dart';
import '../providers/production_providers.dart';

/// Requirement: "Жауапты шебер тағайындау" — backed by `get_masters()`,
/// not the Employees module's employee picker (see that RPC's doc
/// comment for why).
class MasterPickerSheet extends ConsumerWidget {
  const MasterPickerSheet({super.key, this.currentMasterId});

  final String? currentMasterId;

  static Future<ProductionMaster?> open(
    BuildContext context, {
    String? currentMasterId,
  }) {
    return showAppBottomSheet<ProductionMaster>(
      context: context,
      child: MasterPickerSheet(currentMasterId: currentMasterId),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final mastersAsync = ref.watch(productionMastersProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          strings.productionSelectMasterTitle,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.lg),
        mastersAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
            child: LoadingView(),
          ),
          error: (error, _) => Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
            child: Text(strings.productionMastersLoadError),
          ),
          data: (masters) {
            if (masters.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                child: Text(strings.productionNoMastersAvailable),
              );
            }
            return Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final master in masters)
                    ListTile(
                      onTap: () => Navigator.of(context).pop(master),
                      leading: const Icon(LucideIcons.hardHat),
                      trailing: master.userId == currentMasterId
                          ? const Icon(LucideIcons.check, size: 18)
                          : null,
                      title: Text(
                        master.fullName,
                        style: TextStyle(
                          fontWeight: master.userId == currentMasterId
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
