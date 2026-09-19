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
import '../../../../core/widgets/state_views.dart';
import '../../domain/value_objects/order_status.dart';
import '../providers/order_providers.dart';
import '../widgets/order_list_tile.dart';
import '../widgets/order_status_x.dart';

class OrdersListScreen extends ConsumerStatefulWidget {
  const OrdersListScreen({super.key});

  @override
  ConsumerState<OrdersListScreen> createState() => _OrdersListScreenState();
}

class _OrdersListScreenState extends ConsumerState<OrdersListScreen> {
  late final _search = DebouncedSearchController(
    onSearch: (value) =>
        ref.read(orderSearchQueryProvider.notifier).state = value,
  );

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(ordersRealtimeProvider);
    final strings = ref.watch(appStringsProvider);
    final ordersAsync = ref.watch(ordersListProvider);
    final statusFilter = ref.watch(orderStatusFilterProvider);

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: Text(strings.navOrders),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final created = await context.push<bool>(RoutePaths.orderNew);
          if (created == true) ref.invalidate(ordersListProvider);
        },
        child: const Icon(LucideIcons.plus),
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
                hintText: strings.orderSearchHint,
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
                    label: strings.orderFilterAll,
                    selected: statusFilter == null,
                    onTap: () =>
                        ref.read(orderStatusFilterProvider.notifier).state =
                            null,
                  ),
                  for (final status in OrderStatus.values)
                    _FilterChip(
                      label: status.label(strings),
                      selected: statusFilter == status,
                      color: status.color,
                      onTap: () =>
                          ref.read(orderStatusFilterProvider.notifier).state =
                              status,
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Expanded(
              child: ordersAsync.when(
                loading: () => const LoadingView(),
                error: (error, _) => ErrorView(
                  message: strings.dashboardLoadError,
                  retryLabel: strings.commonRetry,
                  onRetry: () => ref.invalidate(ordersListProvider),
                ),
                data: (orders) {
                  if (orders.isEmpty) {
                    return EmptyView(
                      icon: LucideIcons.clipboardList,
                      title: strings.ordersEmptyTitle,
                      description: strings.ordersEmptyDescription,
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () async => ref.invalidate(ordersListProvider),
                    child: context.isMobile
                        ? ListView.builder(
                            itemCount: orders.length,
                            itemBuilder: (context, index) => OrderListTile(
                              order: orders[index],
                              onTap: () async {
                                final changed = await context.push<bool>(
                                  RoutePaths.orderDetail(orders[index].id),
                                );
                                if (changed == true) {
                                  ref.invalidate(ordersListProvider);
                                }
                              },
                            ),
                          )
                        : GridView.builder(
                            gridDelegate:
                                const SliverGridDelegateWithMaxCrossAxisExtent(
                                  maxCrossAxisExtent: 420,
                                  mainAxisExtent: 168,
                                  crossAxisSpacing: AppSpacing.md,
                                  mainAxisSpacing: AppSpacing.md,
                                ),
                            itemCount: orders.length,
                            itemBuilder: (context, index) => OrderListTile(
                              order: orders[index],
                              onTap: () async {
                                final changed = await context.push<bool>(
                                  RoutePaths.orderDetail(orders[index].id),
                                );
                                if (changed == true) {
                                  ref.invalidate(ordersListProvider);
                                }
                              },
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
    this.color,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? AppColors.skyDeep;
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: MotionInkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: selected ? chipColor : chipColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : chipColor,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
