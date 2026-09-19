import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/local_notification_repository_impl.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notification_repository.dart';
import '../../domain/usecases/get_recent_notifications_usecase.dart';
import '../../domain/usecases/mark_notification_read_usecase.dart';
import '../../domain/usecases/record_notification_usecase.dart';

/// Kept alive for the app's lifetime (not `.autoDispose`) — unlike a
/// screen-scoped list provider, the notification feed should survive
/// navigating away from whatever screen last touched it. Swapping in
/// a Firebase/APNS-backed [NotificationRepository] later is a one-line
/// change here; nothing that depends on the interface needs to move.
final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  final repository = LocalNotificationRepositoryImpl();
  ref.onDispose(repository.dispose);
  return repository;
});

final getRecentNotificationsUseCaseProvider =
    Provider<GetRecentNotificationsUseCase>((ref) {
      return GetRecentNotificationsUseCase(
        ref.watch(notificationRepositoryProvider),
      );
    });

final markNotificationReadUseCaseProvider =
    Provider<MarkNotificationReadUseCase>((ref) {
      return MarkNotificationReadUseCase(
        ref.watch(notificationRepositoryProvider),
      );
    });

final recordNotificationUseCaseProvider = Provider<RecordNotificationUseCase>((
  ref,
) {
  return RecordNotificationUseCase(ref.watch(notificationRepositoryProvider));
});

final recentNotificationsProvider = FutureProvider<List<AppNotification>>((
  ref,
) {
  return ref
      .watch(getRecentNotificationsUseCaseProvider)
      .call()
      .then(
        (either) => either.match((failure) => throw failure, (data) => data),
      );
});

/// Drives the bell icon's badge — derived from
/// [recentNotificationsProvider] rather than its own fetch, so the
/// badge and the list screen are always showing the same data.
final unreadNotificationCountProvider = Provider<int>((ref) {
  return ref
      .watch(recentNotificationsProvider)
      .maybeWhen(
        data: (notifications) => notifications.where((n) => !n.read).length,
        orElse: () => 0,
      );
});
