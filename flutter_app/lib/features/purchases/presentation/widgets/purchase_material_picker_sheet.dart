import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/i18n/locale_provider.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../warehouse/domain/entities/material_stock.dart';
import '../../../warehouse/presentation/providers/warehouse_providers.dart';

/// Requirement: "Material Picker" — a local, one-off fetch via
/// [getMaterialsUseCaseProvider] (Warehouse's own usecase, reused
/// directly) rather than the shared `materialsListProvider`, so typing
/// a search here never mutates the Warehouse Materials screen's own
/// filter state. `get_materials()` itself already accepts
/// `purchases.read`/`.write` (see
/// supabase/migrations/20260713000022_purchases_module.sql), so a
/// Manager without `warehouse.read` can still use this picker.
class PurchaseMaterialPickerSheet extends ConsumerStatefulWidget {
  const PurchaseMaterialPickerSheet({super.key});

  static Future<MaterialStock?> open(BuildContext context) {
    return showAppBottomSheet<MaterialStock>(
      context: context,
      child: const PurchaseMaterialPickerSheet(),
    );
  }

  @override
  ConsumerState<PurchaseMaterialPickerSheet> createState() =>
      _PurchaseMaterialPickerSheetState();
}

class _PurchaseMaterialPickerSheetState
    extends ConsumerState<PurchaseMaterialPickerSheet> {
  final _searchController = TextEditingController();
  late Future<List<MaterialStock>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<MaterialStock>> _load() {
    return ref
        .read(getMaterialsUseCaseProvider)
        .call(search: _searchController.text)
        .then((either) => either.match((failure) => throw failure, (d) => d));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          strings.purchasesSelectMaterialTitle,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.lg),
        AppTextField(
          label: strings.commonSearch,
          controller: _searchController,
          prefixIcon: LucideIcons.search,
          onSubmitted: (_) => setState(() => _future = _load()),
        ),
        const SizedBox(height: AppSpacing.md),
        FutureBuilder<List<MaterialStock>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                child: LoadingView(),
              );
            }
            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                child: Text(strings.purchasesMaterialsLoadError),
              );
            }
            final materials = snapshot.data ?? const [];
            if (materials.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                child: Text(strings.purchasesNoMaterialsAvailable),
              );
            }
            return Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final material in materials)
                    ListTile(
                      onTap: () => Navigator.of(context).pop(material),
                      leading: const Icon(LucideIcons.boxes),
                      title: Text(material.name),
                      subtitle: material.categoryNameKk != null
                          ? Text(material.categoryNameKk!)
                          : null,
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
