import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/widgets/press_motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/i18n/locale_provider.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/debounced_search_controller.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/state_views.dart';
import '../providers/issue_cart_provider.dart';
import '../providers/warehouse_providers.dart';
import '../widgets/issue_cart_sheet.dart';
import '../widgets/material_list_tile.dart';
import '../widgets/materials_table.dart';
import '../widgets/warehouse_summary_sheet.dart';
import 'warehouse_scanner_screen.dart';

/// Requirement: "Қойма қалдығы" — phone gets a card list, tablet/desktop
/// a data table (see materials_table.dart's doc comment for why Table
/// was chosen over Kanban).
class MaterialsScreen extends ConsumerStatefulWidget {
  const MaterialsScreen({super.key});

  @override
  ConsumerState<MaterialsScreen> createState() => _MaterialsScreenState();
}

class _MaterialsScreenState extends ConsumerState<MaterialsScreen> {
  late final _search = DebouncedSearchController(
    onSearch: (value) =>
        ref.read(materialsSearchQueryProvider.notifier).state = value,
  );

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _scan(BuildContext context) async {
    final materialId = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const WarehouseScannerScreen()),
    );
    if (!context.mounted) return;
    if (materialId != null) {
      context.push(RoutePaths.warehouseMaterialDetail(materialId));
    } else {
      AppToast.show(
        ref.read(appStringsProvider).warehouseScanNotFoundToast,
        tone: ToastTone.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(materialsRealtimeProvider);
    ref.watch(inventoryBalancesRealtimeProvider);
    final strings = ref.watch(appStringsProvider);
    final categoriesAsync = ref.watch(materialCategoriesProvider);
    final materialsAsync = ref.watch(materialsListProvider);
    final categoryFilter = ref.watch(materialsCategoryFilterProvider);
    final lowStockOnly = ref.watch(materialsLowStockOnlyProvider);
    final cartCount = ref.watch(issueCartProvider).length;

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: Text(strings.navWarehouse),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.barChart3),
            tooltip: strings.warehouseSummaryTitle,
            onPressed: () => WarehouseSummarySheet.open(context),
          ),
          IconButton(
            icon: const Icon(LucideIcons.scanLine),
            tooltip: strings.warehouseScanTitle,
            onPressed: () => _scan(context),
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(LucideIcons.shoppingCart),
                tooltip: strings.warehouseCartTitle,
                onPressed: () => IssueCartSheet.open(context),
              ),
              if (cartCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: AppColors.danger,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '$cartCount',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: context.pageInsets,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _search.textController,
              onChanged: _search.onChanged,
              decoration: InputDecoration(
                hintText: strings.warehouseSearchHint,
                prefixIcon: const Icon(LucideIcons.search, size: 20),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 40,
              child: categoriesAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (error, _) => const SizedBox.shrink(),
                data: (categories) => ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _FilterChip(
                      label: strings.warehouseFilterAllCategories,
                      selected: categoryFilter == null,
                      onTap: () =>
                          ref
                                  .read(
                                    materialsCategoryFilterProvider.notifier,
                                  )
                                  .state =
                              null,
                    ),
                    for (final category in categories)
                      Padding(
                        padding: const EdgeInsets.only(left: AppSpacing.sm),
                        child: _FilterChip(
                          label: category.nameKk,
                          selected: categoryFilter == category.id,
                          onTap: () =>
                              ref
                                  .read(
                                    materialsCategoryFilterProvider.notifier,
                                  )
                                  .state = category
                                  .id,
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(left: AppSpacing.sm),
                      child: _FilterChip(
                        label: strings.warehouseLowStockFilterLabel,
                        selected: lowStockOnly,
                        icon: LucideIcons.alertTriangle,
                        onTap: () =>
                            ref
                                    .read(
                                      materialsLowStockOnlyProvider.notifier,
                                    )
                                    .state =
                                !lowStockOnly,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Expanded(
              child: materialsAsync.when(
                loading: () => const LoadingView(),
                error: (error, _) => ErrorView(
                  message: strings.warehouseLoadError,
                  retryLabel: strings.commonRetry,
                  onRetry: () => ref.invalidate(materialsListProvider),
                ),
                data: (materials) {
                  if (materials.isEmpty) {
                    return EmptyView(
                      icon: LucideIcons.packageOpen,
                      title: strings.warehouseEmptyTitle,
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () async =>
                        ref.invalidate(materialsListProvider),
                    child: context.isMobile
                        ? ListView.builder(
                            itemCount: materials.length,
                            itemBuilder: (context, index) => MaterialListTile(
                              material: materials[index],
                              onTap: () => context.push(
                                RoutePaths.warehouseMaterialDetail(
                                  materials[index].materialId,
                                ),
                              ),
                            ),
                          )
                        : SingleChildScrollView(
                            child: MaterialsTable(
                              materials: materials,
                              onRowTap: (material) => context.push(
                                RoutePaths.warehouseMaterialDetail(
                                  material.materialId,
                                ),
                              ),
                              columnMaterial:
                                  strings.warehouseTableColumnMaterial,
                              columnCategory:
                                  strings.warehouseTableColumnCategory,
                              columnAvailable:
                                  strings.warehouseTableColumnAvailable,
                              columnReserved:
                                  strings.warehouseTableColumnReserved,
                              columnMin: strings.warehouseTableColumnMin,
                            ),
                          ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return MotionInkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.skyDeep
              : AppColors.skyDeep.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: selected ? Colors.white : AppColors.skyDeep,
              ),
              const SizedBox(width: AppSpacing.xs),
            ],
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : AppColors.skyDeep,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
