import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/i18n/locale_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/production_stage.dart';
import '../../domain/entities/production_time_log.dart';
import '../../domain/production_qr.dart';
import '../providers/production_providers.dart';

/// Requirement: "Уақыт журналдары" — a start/stop timer for the
/// current stage, plus the order's full time-log history.
class ProductionTimeLogSection extends ConsumerWidget {
  const ProductionTimeLogSection({
    super.key,
    required this.orderId,
    required this.currentStage,
    required this.timeLogs,
    required this.canWrite,
  });

  final String orderId;
  final ProductionStage currentStage;
  final List<ProductionTimeLog> timeLogs;
  final bool canWrite;

  Future<void> _start(BuildContext context, WidgetRef ref) async {
    final strings = ref.read(appStringsProvider);
    final result = await ref
        .read(startTimeLogUseCaseProvider)
        .call(orderId: orderId, stageId: currentStage.id);
    if (!context.mounted) return;
    result.match(
      (failure) => AppToast.show(failure.message, tone: ToastTone.error),
      (_) {
        AppToast.show(
          strings.productionTimeLogStartedToast,
          tone: ToastTone.success,
        );
        ref.invalidate(productionOrderDetailProvider(orderId));
      },
    );
  }

  Future<void> _stop(BuildContext context, WidgetRef ref, String logId) async {
    final strings = ref.read(appStringsProvider);
    final result = await ref.read(stopTimeLogUseCaseProvider).call(logId);
    if (!context.mounted) return;
    result.match(
      (failure) => AppToast.show(failure.message, tone: ToastTone.error),
      (_) {
        AppToast.show(
          strings.productionTimeLogStoppedToast,
          tone: ToastTone.success,
        );
        ref.invalidate(productionOrderDetailProvider(orderId));
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final textTheme = Theme.of(context).textTheme;
    final currentUserId = ref.watch(currentUserProvider)?.id;

    final myOpenLog = timeLogs
        .where((log) => log.isOpen && log.employeeId == currentUserId)
        .firstOrNull;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(strings.productionTimeLogsTitle, style: textTheme.titleMedium),
          const SizedBox(height: AppSpacing.md),
          if (canWrite)
            AppButton(
              label: myOpenLog != null
                  ? strings.productionStopTimerAction
                  : strings.productionStartTimerAction,
              icon: myOpenLog != null ? LucideIcons.square : LucideIcons.play,
              variant: myOpenLog != null
                  ? AppButtonVariant.destructive
                  : AppButtonVariant.secondary,
              onPressed: () => myOpenLog != null
                  ? _stop(context, ref, myOpenLog.id!)
                  : _start(context, ref),
            ),
          const SizedBox(height: AppSpacing.md),
          if (timeLogs.isEmpty)
            Text(strings.productionNoTimeLogs, style: textTheme.bodyMedium)
          else
            for (final log in timeLogs)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      log.isOpen ? LucideIcons.timer : LucideIcons.checkCircle2,
                      size: 16,
                      color: log.isOpen
                          ? AppColors.warning
                          : AppColors.textSecondaryLight,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(log.employeeName, style: textTheme.bodyMedium),
                          Text(
                            '${AppFormatters.dateTime(log.startedAt)} — '
                            '${log.endedAt != null ? AppFormatters.dateTime(log.endedAt!) : strings.productionTimeLogOngoing}'
                            '${log.stageNameKk != null ? ' · ${log.stageNameKk}' : ''}',
                            style: textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _formatDuration(
                        computeTimeLogDuration(
                          startedAt: log.startedAt,
                          endedAt: log.endedAt,
                          now: DateTime.now(),
                        ),
                      ),
                      style: textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes % 60;
    return '$hoursс $minutesмин';
  }
}
