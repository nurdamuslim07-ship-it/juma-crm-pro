import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/i18n/locale_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../domain/entities/production_queue_item.dart';
import '../../domain/entities/production_stage.dart';
import '../providers/production_providers.dart';
import 'production_kanban_card.dart';

/// Requirement: "Цех тақтасы (Kanban)" + "Drag & Drop Kanban" —
/// tablet/web only (see production_queue_screen.dart's
/// `context.isMobile` branch); phone gets the plain queue list
/// instead, since 9 side-scrolling columns don't fit a phone width.
class ProductionKanbanBoard extends ConsumerWidget {
  const ProductionKanbanBoard({
    super.key,
    required this.stages,
    required this.items,
    required this.canMoveCards,
    required this.onCardTap,
  });

  final List<ProductionStage> stages;
  final List<ProductionQueueItem> items;
  final bool canMoveCards;
  final void Function(ProductionQueueItem item) onCardTap;

  Future<void> _handleDrop(
    BuildContext context,
    WidgetRef ref,
    ProductionQueueItem item,
    ProductionStage targetStage,
  ) async {
    if (item.stageId == targetStage.id) return;
    final strings = ref.read(appStringsProvider);
    final result = await ref
        .read(moveOrderToStageUseCaseProvider)
        .call(orderId: item.orderId, stageId: targetStage.id);
    if (!context.mounted) return;
    result.match(
      (failure) => AppToast.show(failure.message, tone: ToastTone.error),
      (_) {
        ref.invalidate(productionQueueProvider);
        AppToast.show(
          strings.productionStageMovedToast,
          tone: ToastTone.success,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final stage in stages)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.md),
              child: _KanbanColumn(
                stage: stage,
                items: items.where((i) => i.stageId == stage.id).toList(),
                canMoveCards: canMoveCards,
                onCardTap: onCardTap,
                onAccept: (item) => _handleDrop(context, ref, item, stage),
                emptyLabel: strings.productionColumnEmpty,
              ),
            ),
        ],
      ),
    );
  }
}

class _KanbanColumn extends StatelessWidget {
  const _KanbanColumn({
    required this.stage,
    required this.items,
    required this.canMoveCards,
    required this.onCardTap,
    required this.onAccept,
    required this.emptyLabel,
  });

  final ProductionStage stage;
  final List<ProductionQueueItem> items;
  final bool canMoveCards;
  final void Function(ProductionQueueItem item) onCardTap;
  final void Function(ProductionQueueItem item) onAccept;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    return DragTarget<ProductionQueueItem>(
      onWillAcceptWithDetails: (details) => canMoveCards,
      onAcceptWithDetails: (details) => onAccept(details.data),
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;
        return Container(
          width: 240,
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: isHovering
                ? AppColors.skyDeep.withValues(alpha: 0.12)
                : AppColors.skyDeep.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: isHovering
                  ? AppColors.skyDeep
                  : AppColors.skyDeep.withValues(alpha: 0.15),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs,
                  vertical: AppSpacing.xs,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        stage.nameKk,
                        style: Theme.of(context).textTheme.titleSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${items.length}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              SizedBox(
                height: 520,
                child: items.isEmpty
                    ? Center(
                        child: Text(
                          emptyLabel,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      )
                    : ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          final card = Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.sm,
                            ),
                            child: ProductionKanbanCard(
                              item: item,
                              onTap: () => onCardTap(item),
                            ),
                          );
                          if (!canMoveCards) return card;
                          return LongPressDraggable<ProductionQueueItem>(
                            data: item,
                            feedback: Material(
                              color: Colors.transparent,
                              child: ProductionKanbanCard(
                                item: item,
                                width: 220,
                              ),
                            ),
                            childWhenDragging: Opacity(
                              opacity: 0.3,
                              child: card,
                            ),
                            child: card,
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
