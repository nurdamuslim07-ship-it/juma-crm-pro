import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/widgets/press_motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/i18n/locale_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/state_views.dart';
import '../../domain/entities/app_notification.dart';
import '../providers/notification_providers.dart';

/// Stage 4 Part 2's UI, on top of the already-built domain/data layer
/// ([NotificationRepository] et al.) — no backend change of any kind,
/// this is purely a presentation layer that was missing.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  Future<void> _markAsRead(WidgetRef ref, AppNotification notification) async {
    if (notification.read) return;
    final result = await ref
        .read(markNotificationReadUseCaseProvider)
        .call(notification.id);
    result.match((_) {}, (_) => ref.invalidate(recentNotificationsProvider));
  }

  Future<void> _markAllAsRead(WidgetRef ref, List<AppNotification> all) async {
    final markUseCase = ref.read(markNotificationReadUseCaseProvider);
    for (final n in all.where((n) => !n.read)) {
      await markUseCase.call(n.id);
    }
    ref.invalidate(recentNotificationsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final notificationsAsync = ref.watch(recentNotificationsProvider);

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: Text(strings.notificationsTitle),
        actions: [
          notificationsAsync.maybeWhen(
            data: (all) => all.any((n) => !n.read)
                ? IconButton(
                    icon: const Icon(LucideIcons.checkCheck),
                    tooltip: strings.notificationsMarkAllReadAction,
                    onPressed: () => _markAllAsRead(ref, all),
                  )
                : const SizedBox.shrink(),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(recentNotificationsProvider),
        child: notificationsAsync.when(
          loading: () => const LoadingView(),
          error: (error, _) => ErrorView(message: strings.dashboardLoadError),
          data: (notifications) {
            if (notifications.isEmpty) {
              return ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.huge,
                    ),
                    child: EmptyView(
                      icon: LucideIcons.bellOff,
                      title: strings.notificationsEmptyTitle,
                      description: strings.notificationsEmptyDescription,
                    ),
                  ),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              itemCount: notifications.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return _NotificationTile(
                  notification: notification,
                  onTap: () => _markAsRead(ref, notification),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, required this.onTap});

  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final unread = !notification.read;
    return MotionInkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: unread
              ? AppColors.skyDeep.withValues(alpha: 0.08)
              : Colors.transparent,
          border: Border.all(
            color: unread
                ? AppColors.skyDeep.withValues(alpha: 0.2)
                : Theme.of(context).dividerColor,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (unread)
              Padding(
                padding: const EdgeInsets.only(top: 6, right: AppSpacing.sm),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.skyDeep,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: unread ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    notification.body,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppFormatters.dateTime(notification.createdAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).hintColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
