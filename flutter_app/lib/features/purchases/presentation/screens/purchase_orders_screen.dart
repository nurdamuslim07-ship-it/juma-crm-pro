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
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/purchase_order_status.dart';
import '../../domain/value_objects/purchase_date_range.dart';
import '../providers/purchases_providers.dart';
import '../widgets/purchase_order_list_tile.dart';
import '../widgets/purchase_order_status_x.dart';
import '../widgets/purchase_orders_table.dart';
import '../widgets/supplier_picker_sheet.dart';

const _pageSize = 20;

/// Requirement: "Purchase Orders" screen — phone gets a card list,
/// tablet/desktop a data table (see purchase_orders_table.dart's doc
/// comment for why Table was chosen over Kanban).
class PurchaseOrdersScreen extends ConsumerStatefulWidget {
  const PurchaseOrdersScreen({super.key});

  @override
  ConsumerState<PurchaseOrdersScreen> createState() =>
      _PurchaseOrdersScreenState();
}

class _PurchaseOrdersScreenState extends ConsumerState<PurchaseOrdersScreen> {
  late final _search = DebouncedSearchController(
    onSearch: (value) =>
        ref.read(purchaseOrdersSearchQueryProvider.notifier).state = value,
  );
  int _visibleCount = _pageSize;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _pickSupplierFilter() async {
    final current = ref.read(purchaseOrdersSupplierFilterProvider);
    final picked = await SupplierPickerSheet.open(
      context,
      currentPartnerId: current?.id,
    );
    if (picked == null) return;
    ref.read(purchaseOrdersSupplierFilterProvider.notifier).state = picked;
    setState(() => _visibleCount = _pageSize);
  }

  Future<void> _pickDateRange() async {
    final current = ref.read(purchaseOrdersDateRangeProvider);
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
      initialDateRange: current == null
          ? null
          : DateTimeRange(start: current.from, end: current.to),
    );
    if (picked == null) return;
    ref.read(purchaseOrdersDateRangeProvider.notifier).state =
        PurchaseDateRange(from: picked.start, to: picked.end);
    setState(() => _visibleCount = _pageSize);
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);
    final ordersAsync = ref.watch(purchaseOrdersListProvider);
    final statusFilter = ref.watch(purchaseOrdersStatusFilterProvider);
    final supplierFilter = ref.watch(purchaseOrdersSupplierFilterProvider);
    final dateRangeFilter = ref.watch(purchaseOrdersDateRangeProvider);
    final currentUser = ref.watch(currentUserProvider);
    final canWrite = currentUser?.canWritePurchases ?? false;

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: Text(strings.navPurchases),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.barChart3),
            tooltip: strings.purchasesAnalyticsTitle,
            onPressed: () => context.push(RoutePaths.purchasesAnalytics),
          ),
        ],
      ),
      floatingActionButton: canWrite
          ? FloatingActionButton.extended(
              onPressed: () => context.push(RoutePaths.purchaseOrderNew),
              icon: const Icon(LucideIcons.plus),
              label: Text(strings.purchasesCreateAction),
            )
          : null,
      body: Padding(
        padding: context.pageInsets,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _search.textController,
              onChanged: _search.onChanged,
              decoration: InputDecoration(
                hintText: strings.purchasesSearchHint,
                prefixIcon: const Icon(LucideIcons.search, size: 20),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _FilterChip(
                    label: strings.purchasesFilterAllStatuses,
                    selected: statusFilter == null,
                    onTap: () =>
                        ref
                                .read(
                                  purchaseOrdersStatusFilterProvider.notifier,
                                )
                                .state =
                            null,
                  ),
                  for (final status in PurchaseOrderStatus.values)
                    Padding(
                      padding: const EdgeInsets.only(left: AppSpacing.sm),
                      child: _FilterChip(
                        label: status.nameKk(strings),
                        icon: status.icon,
                        selected: statusFilter == status,
                        onTap: () =>
                            ref
                                    .read(
                                      purchaseOrdersStatusFilterProvider
                                          .notifier,
                                    )
                                    .state =
                                status,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _FilterButton(
                    icon: LucideIcons.building2,
                    label:
                        supplierFilter?.displayName ??
                        strings.purchasesSupplierFilterLabel,
                    active: supplierFilter != null,
                    onTap: _pickSupplierFilter,
                    onClear: supplierFilter == null
                        ? null
                        : () {
                            ref
                                    .read(
                                      purchaseOrdersSupplierFilterProvider
                                          .notifier,
                                    )
                                    .state =
                                null;
                            setState(() => _visibleCount = _pageSize);
                          },
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _FilterButton(
                    icon: LucideIcons.calendarRange,
                    label: dateRangeFilter == null
                        ? strings.purchasesDateRangeLabel
                        : '${AppFormatters.date(dateRangeFilter.from)} – '
                              '${AppFormatters.date(dateRangeFilter.to)}',
                    active: dateRangeFilter != null,
                    onTap: _pickDateRange,
                    onClear: dateRangeFilter == null
                        ? null
                        : () {
                            ref
                                    .read(
                                      purchaseOrdersDateRangeProvider.notifier,
                                    )
                                    .state =
                                null;
                            setState(() => _visibleCount = _pageSize);
                          },
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Expanded(
              child: ordersAsync.when(
                loading: () => const LoadingView(),
                error: (error, _) => ErrorView(
                  message: strings.purchasesLoadError,
                  retryLabel: strings.commonRetry,
                  onRetry: () => ref.invalidate(purchaseOrdersListProvider),
                ),
                data: (orders) {
                  final filtered = dateRangeFilter == null
                      ? orders
                      : orders
                            .where(
                              (order) =>
                                  dateRangeFilter.contains(order.createdAt),
                            )
                            .toList();
                  if (filtered.isEmpty) {
                    return EmptyView(
                      icon: LucideIcons.clipboardList,
                      title: strings.purchasesEmptyTitle,
                    );
                  }
                  final visible = filtered.take(_visibleCount).toList();
                  final hasMore = visible.length < filtered.length;
                  return RefreshIndicator(
                    onRefresh: () async =>
                        ref.invalidate(purchaseOrdersListProvider),
                    child: ListView(
                      children: [
                        context.isMobile
                            ? Column(
                                children: [
                                  for (final order in visible)
                                    PurchaseOrderListTile(
                                      order: order,
                                      strings: strings,
                                      onTap: () => context.push(
                                        RoutePaths.purchaseOrderDetail(
                                          order.id,
                                        ),
                                      ),
                                    ),
                                ],
                              )
                            : PurchaseOrdersTable(
                                orders: visible,
                                strings: strings,
                                onRowTap: (order) => context.push(
                                  RoutePaths.purchaseOrderDetail(order.id),
                                ),
                                columnNumber:
                                    strings.purchasesTableColumnNumber,
                                columnSupplier:
                                    strings.purchasesTableColumnSupplier,
                                columnStatus:
                                    strings.purchasesTableColumnStatus,
                                columnTotal: strings.purchasesTableColumnTotal,
                                columnExpectedDate:
                                    strings.purchasesTableColumnExpectedDate,
                              ),
                        if (hasMore)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.lg,
                            ),
                            child: Center(
                              child: TextButton.icon(
                                onPressed: () =>
                                    setState(() => _visibleCount += _pageSize),
                                icon: const Icon(LucideIcons.chevronDown),
                                label: Text(strings.purchasesLoadMoreAction),
                              ),
                            ),
                          ),
                      ],
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

class _FilterButton extends StatelessWidget {
  const _FilterButton({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
    this.onClear,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  final VoidCallback? onClear;

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
          color: active
              ? AppColors.skyDeep.withValues(alpha: 0.15)
              : AppColors.skyDeep.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: AppColors.skyDeep),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.skyDeep,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ),
            if (onClear != null)
              MotionInkWell(
                onTap: onClear,
                child: const Icon(
                  LucideIcons.x,
                  size: 14,
                  color: AppColors.skyDeep,
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
