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
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/partner_providers.dart';
import '../widgets/partner_category_picker_sheet.dart';
import '../widgets/partner_category_x.dart';
import '../widgets/partner_list_tile.dart';
import '../widgets/partner_status_picker_sheet.dart';

class PartnersListScreen extends ConsumerStatefulWidget {
  const PartnersListScreen({super.key});

  @override
  ConsumerState<PartnersListScreen> createState() => _PartnersListScreenState();
}

class _PartnersListScreenState extends ConsumerState<PartnersListScreen> {
  late final _search = DebouncedSearchController(
    onSearch: (value) =>
        ref.read(partnerSearchQueryProvider.notifier).state = value,
  );

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _pickCategory() async {
    final result = await PartnerCategoryPickerSheet.open(
      context,
      current: ref.read(partnerCategoryFilterProvider),
    );
    final unwrapped = unwrapPickedCategory(result);
    if (unwrapped.picked) {
      ref.read(partnerCategoryFilterProvider.notifier).state = unwrapped.value;
    }
  }

  Future<void> _pickStatus() async {
    final result = await PartnerStatusPickerSheet.open(
      context,
      current: ref.read(partnerActiveFilterProvider),
    );
    final unwrapped = unwrapPartnerPickedStatus(result);
    if (unwrapped.picked) {
      ref.read(partnerActiveFilterProvider.notifier).state = unwrapped.value;
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);
    final currentUser = ref.watch(currentUserProvider);
    final canWrite = currentUser?.canWritePartners ?? false;
    final isDirector = currentUser?.isDirector ?? false;

    final searchQuery = ref.watch(partnerSearchQueryProvider);
    final categoryFilter = ref.watch(partnerCategoryFilterProvider);
    final activeFilter = ref.watch(partnerActiveFilterProvider);
    final showTrash = ref.watch(partnerShowTrashProvider);

    final filter = (
      search: searchQuery,
      category: categoryFilter,
      active: activeFilter,
      includeDeleted: showTrash,
    );
    final partnersAsync = ref.watch(partnersListProvider(filter));

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: Text(strings.navPartners),
        actions: [
          if (isDirector)
            IconButton(
              tooltip: showTrash
                  ? strings.partnerShowActiveAction
                  : strings.partnerShowTrashAction,
              icon: Icon(showTrash ? LucideIcons.undo2 : LucideIcons.trash2),
              onPressed: () =>
                  ref.read(partnerShowTrashProvider.notifier).state =
                      !showTrash,
            ),
        ],
      ),
      floatingActionButton: canWrite && !showTrash
          ? FloatingActionButton(
              onPressed: () async {
                final created = await context.push<bool>(RoutePaths.partnerNew);
                if (created == true) {
                  ref.invalidate(partnersListProvider(filter));
                }
              },
              child: const Icon(LucideIcons.plus),
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
                hintText: strings.partnersSearchHint,
                prefixIcon: const Icon(LucideIcons.search, size: 20),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _FilterButton(
                    icon: categoryFilter?.icon ?? LucideIcons.tags,
                    label:
                        categoryFilter?.label(strings) ??
                        strings.partnerFilterAllCategories,
                    onTap: _pickCategory,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _FilterButton(
                    icon: LucideIcons.userCheck,
                    label: switch (activeFilter) {
                      true => strings.partnerFilterActive,
                      false => strings.partnerFilterInactive,
                      null => strings.partnerFilterAllStatuses,
                    },
                    onTap: _pickStatus,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Expanded(
              child: partnersAsync.when(
                loading: () => const LoadingView(),
                error: (error, _) => ErrorView(
                  message: strings.partnersLoadError,
                  retryLabel: strings.commonRetry,
                  onRetry: () =>
                      ref.read(partnersListProvider(filter).notifier).refresh(),
                ),
                data: (page) {
                  if (page.items.isEmpty) {
                    return EmptyView(
                      icon: LucideIcons.users2,
                      title: showTrash
                          ? strings.partnersTrashEmptyTitle
                          : strings.partnersEmptyTitle,
                      description: !showTrash && canWrite
                          ? strings.partnersEmptyDescription
                          : null,
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () => ref
                        .read(partnersListProvider(filter).notifier)
                        .refresh(),
                    child: context.isMobile
                        ? ListView.builder(
                            itemCount: page.items.length + 1,
                            itemBuilder: (context, index) =>
                                index == page.items.length
                                ? _LoadMoreRow(
                                    hasMore: page.hasMore,
                                    onLoadMore: () => ref
                                        .read(
                                          partnersListProvider(filter).notifier,
                                        )
                                        .loadMore(),
                                  )
                                : PartnerListTile(
                                    partner: page.items[index],
                                    onTap: () => context.push(
                                      RoutePaths.partnerDetail(
                                        page.items[index].id,
                                      ),
                                    ),
                                  ),
                          )
                        : ListView(
                            children: [
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    const SliverGridDelegateWithMaxCrossAxisExtent(
                                      maxCrossAxisExtent: 420,
                                      mainAxisExtent: 96,
                                      crossAxisSpacing: AppSpacing.md,
                                      mainAxisSpacing: AppSpacing.md,
                                    ),
                                itemCount: page.items.length,
                                itemBuilder: (context, index) =>
                                    PartnerListTile(
                                      partner: page.items[index],
                                      onTap: () => context.push(
                                        RoutePaths.partnerDetail(
                                          page.items[index].id,
                                        ),
                                      ),
                                    ),
                              ),
                              _LoadMoreRow(
                                hasMore: page.hasMore,
                                onLoadMore: () => ref
                                    .read(partnersListProvider(filter).notifier)
                                    .loadMore(),
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

class _LoadMoreRow extends ConsumerWidget {
  const _LoadMoreRow({required this.hasMore, required this.onLoadMore});
  final bool hasMore;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!hasMore) return const SizedBox.shrink();
    final strings = ref.watch(appStringsProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: AppButton(
        label: strings.partnersLoadMoreAction,
        variant: AppButtonVariant.secondary,
        expand: false,
        onPressed: onLoadMore,
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MotionInkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: AppColors.skyDeep.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppColors.skyDeep),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.skyDeep,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
