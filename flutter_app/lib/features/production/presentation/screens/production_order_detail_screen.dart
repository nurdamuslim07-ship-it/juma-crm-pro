import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/widgets/press_motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/i18n/locale_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/production_detail.dart';
import '../providers/production_providers.dart';
import '../widgets/master_picker_sheet.dart';
import '../widgets/material_availability_section.dart';
import '../widgets/production_history_section.dart';
import '../widgets/production_photo_gallery.dart';
import '../widgets/production_qr_code_view.dart';
import '../widgets/production_stage_picker_sheet.dart';
import '../widgets/production_stage_x.dart';
import '../widgets/production_time_log_section.dart';

/// Requirement: "Тапсырыс деталі" — the full production view for one
/// order (stage, responsible master, materials, photos, time logs,
/// history), reached from the queue/Kanban or by scanning the order's
/// QR code.
class ProductionOrderDetailScreen extends ConsumerWidget {
  const ProductionOrderDetailScreen({super.key, required this.orderId});
  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final detailAsync = ref.watch(productionOrderDetailProvider(orderId));

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: Text(strings.productionOrderDetailTitle),
      ),
      body: detailAsync.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorView(
          message: strings.productionOrderNotFound,
          retryLabel: strings.commonRetry,
          onRetry: () => ref.invalidate(productionOrderDetailProvider(orderId)),
        ),
        data: (detail) => _DetailBody(detail: detail),
      ),
    );
  }
}

class _DetailBody extends ConsumerWidget {
  const _DetailBody({required this.detail});
  final ProductionDetail detail;

  Future<void> _pickStage(BuildContext context, WidgetRef ref) async {
    final strings = ref.read(appStringsProvider);
    final stagesEither = await ref.read(productionStagesProvider.future);
    if (!context.mounted) return;
    final current = stagesEither
        .where((s) => s.id == detail.stageId)
        .firstOrNull;
    final result = await ProductionStagePickerSheet.open(
      context,
      stages: stagesEither,
      current: current,
      allowAll: false,
    );
    final unwrapped = unwrapPickedStage(result);
    if (!unwrapped.picked || unwrapped.value == null) return;
    if (!context.mounted) return;

    final moveResult = await ref
        .read(moveOrderToStageUseCaseProvider)
        .call(orderId: detail.orderId, stageId: unwrapped.value!.id);
    if (!context.mounted) return;
    moveResult.match(
      (failure) => AppToast.show(failure.message, tone: ToastTone.error),
      (_) {
        AppToast.show(
          strings.productionStageMovedToast,
          tone: ToastTone.success,
        );
        ref.invalidate(productionOrderDetailProvider(detail.orderId));
        ref.invalidate(productionQueueProvider);
      },
    );
  }

  Future<void> _pickMaster(BuildContext context, WidgetRef ref) async {
    final strings = ref.read(appStringsProvider);
    final picked = await MasterPickerSheet.open(
      context,
      currentMasterId: detail.masterId,
    );
    if (picked == null || !context.mounted) return;

    final result = await ref
        .read(setOrderMasterUseCaseProvider)
        .call(orderId: detail.orderId, masterId: picked.userId);
    if (!context.mounted) return;
    result.match(
      (failure) => AppToast.show(failure.message, tone: ToastTone.error),
      (_) {
        AppToast.show(
          strings.productionMasterAssignedToast,
          tone: ToastTone.success,
        );
        ref.invalidate(productionOrderDetailProvider(detail.orderId));
        ref.invalidate(productionQueueProvider);
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final textTheme = Theme.of(context).textTheme;
    final currentUser = ref.watch(currentUserProvider);
    final canMoveCards = currentUser?.canMoveProductionCards ?? false;
    final canAssignMaster = currentUser?.canAssignMaster ?? false;
    final stagesAsync = ref.watch(productionStagesProvider);
    final currentStage = stagesAsync.valueOrNull
        ?.where((s) => s.id == detail.stageId)
        .firstOrNull;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(detail.orderNumber, style: textTheme.titleLarge),
                        Text(
                          '${detail.productType} · ${detail.clientName}',
                          style: textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  if (currentStage != null)
                    Icon(currentStage.icon, color: AppColors.skyDeep, size: 28),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              MotionInkWell(
                onTap: canMoveCards ? () => _pickStage(context, ref) : null,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              strings.productionCurrentStageLabel,
                              style: textTheme.bodySmall,
                            ),
                            Text(
                              detail.stageNameKk,
                              style: textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${detail.percentComplete}%',
                        style: textTheme.titleMedium,
                      ),
                      if (canMoveCards) ...[
                        const SizedBox(width: AppSpacing.sm),
                        const Icon(LucideIcons.chevronRight, size: 18),
                      ],
                    ],
                  ),
                ),
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: detail.percentComplete / 100,
                  minHeight: 6,
                  backgroundColor: AppColors.skyDeep.withValues(alpha: 0.12),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              MotionInkWell(
                onTap: canAssignMaster ? () => _pickMaster(context, ref) : null,
                borderRadius: BorderRadius.circular(12),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.hardHat,
                      size: 18,
                      color: detail.masterName != null
                          ? AppColors.textSecondaryLight
                          : AppColors.warning,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        detail.masterName ?? strings.productionNoMasterAssigned,
                        style: textTheme.bodyMedium?.copyWith(
                          color: detail.masterName != null
                              ? null
                              : AppColors.warning,
                        ),
                      ),
                    ),
                    if (canAssignMaster)
                      const Icon(LucideIcons.chevronRight, size: 18),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        ProductionQrCodeView(
          orderId: detail.orderId,
          orderNumber: detail.orderNumber,
        ),
        const SizedBox(height: AppSpacing.lg),
        MaterialAvailabilitySection(materials: detail.materials),
        const SizedBox(height: AppSpacing.lg),
        ProductionPhotoGallery(
          orderId: detail.orderId,
          photos: detail.recentPhotos,
          canWrite: canMoveCards,
        ),
        const SizedBox(height: AppSpacing.lg),
        if (currentStage != null)
          ProductionTimeLogSection(
            orderId: detail.orderId,
            currentStage: currentStage,
            timeLogs: detail.timeLogs,
            canWrite: canMoveCards,
          ),
        const SizedBox(height: AppSpacing.lg),
        ProductionHistorySection(history: detail.stageHistory),
        const SizedBox(height: AppSpacing.xl),
        if (canMoveCards)
          AppButton(
            label: strings.productionMoveStageAction,
            icon: LucideIcons.arrowRightCircle,
            onPressed: () => _pickStage(context, ref),
          ),
      ],
    );
  }
}
