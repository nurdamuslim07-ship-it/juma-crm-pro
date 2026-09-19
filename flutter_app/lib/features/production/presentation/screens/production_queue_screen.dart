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
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/production_providers.dart';
import '../widgets/production_kanban_board.dart';
import '../widgets/production_queue_tile.dart';
import '../widgets/production_stage_picker_sheet.dart';
import 'qr_scanner_screen.dart';

/// Requirement: "Өндіріс кезегі" + "Цех тақтасы (Kanban)" — the phone
/// view is a plain filterable queue list; tablet/web gets the
/// drag-and-drop Kanban board instead, per the requirement's explicit
/// "Планшетке арналған интерфейс" tablet focus for the board.
class ProductionQueueScreen extends ConsumerStatefulWidget {
  const ProductionQueueScreen({super.key});

  @override
  ConsumerState<ProductionQueueScreen> createState() =>
      _ProductionQueueScreenState();
}

class _ProductionQueueScreenState extends ConsumerState<ProductionQueueScreen> {
  late final _search = DebouncedSearchController(
    onSearch: (value) =>
        ref.read(productionSearchQueryProvider.notifier).state = value,
  );

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _scanQr(BuildContext context) async {
    final orderId = await Navigator.of(
      context,
    ).push<String>(MaterialPageRoute(builder: (_) => const QrScannerScreen()));
    if (orderId != null && context.mounted) {
      context.push(RoutePaths.productionOrderDetail(orderId));
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(productionRealtimeProvider);
    final strings = ref.watch(appStringsProvider);
    final stagesAsync = ref.watch(productionStagesProvider);
    final queueAsync = ref.watch(productionQueueProvider);
    final currentUser = ref.watch(currentUserProvider);
    final canMoveCards = currentUser?.canMoveProductionCards ?? false;

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: Text(strings.navProduction),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.qrCode),
            tooltip: strings.productionScanQrTitle,
            onPressed: () => _scanQr(context),
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
                hintText: strings.productionSearchHint,
                prefixIcon: const Icon(LucideIcons.search, size: 20),
              ),
            ),
            if (context.isMobile) ...[
              const SizedBox(height: AppSpacing.md),
              stagesAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (error, _) => const SizedBox.shrink(),
                data: (stages) => Consumer(
                  builder: (context, ref, _) {
                    final stageFilter = ref.watch(
                      productionStageFilterProvider,
                    );
                    final selected = stages
                        .where((s) => s.id == stageFilter)
                        .firstOrNull;
                    return _FilterButton(
                      icon: LucideIcons.listFilter,
                      label:
                          selected?.nameKk ?? strings.productionFilterAllStages,
                      onTap: () async {
                        final result = await ProductionStagePickerSheet.open(
                          context,
                          stages: stages,
                          current: selected,
                        );
                        final unwrapped = unwrapPickedStage(result);
                        if (unwrapped.picked) {
                          ref
                                  .read(productionStageFilterProvider.notifier)
                                  .state =
                              unwrapped.value?.id;
                        }
                      },
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            Expanded(
              child: queueAsync.when(
                loading: () => const LoadingView(),
                error: (error, _) => ErrorView(
                  message: strings.productionLoadError,
                  retryLabel: strings.commonRetry,
                  onRetry: () => ref.invalidate(productionQueueProvider),
                ),
                data: (items) {
                  if (items.isEmpty) {
                    return EmptyView(
                      icon: LucideIcons.clipboardList,
                      title: strings.productionQueueEmptyTitle,
                    );
                  }
                  if (context.isMobile) {
                    return RefreshIndicator(
                      onRefresh: () async =>
                          ref.invalidate(productionQueueProvider),
                      child: ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (context, index) => ProductionQueueTile(
                          item: items[index],
                          onTap: () => context.push(
                            RoutePaths.productionOrderDetail(
                              items[index].orderId,
                            ),
                          ),
                        ),
                      ),
                    );
                  }
                  return stagesAsync.when(
                    loading: () => const LoadingView(),
                    error: (error, _) => ErrorView(
                      message: strings.productionLoadError,
                      retryLabel: strings.commonRetry,
                      onRetry: () => ref.invalidate(productionStagesProvider),
                    ),
                    data: (stages) => RefreshIndicator(
                      onRefresh: () async =>
                          ref.invalidate(productionQueueProvider),
                      child: ProductionKanbanBoard(
                        stages: stages,
                        items: items,
                        canMoveCards: canMoveCards,
                        onCardTap: (item) => context.push(
                          RoutePaths.productionOrderDetail(item.orderId),
                        ),
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
