import 'dart:async';

import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notification_repository.dart';

/// In-memory, session-only implementation — "no provider integration
/// yet" per the Stage 4 Part 2 ask, so nothing here talks to Firebase/
/// APNS or persists across app restarts (durable local storage is
/// Part 4/offline-first's territory, a deliberately separate,
/// deferred stage — see supabase/README.md). This exists so the
/// domain layer has ONE real implementation to be tested against and
/// to eventually be swapped for a push-provider-backed one without
/// touching [NotificationRepository]'s callers.
class LocalNotificationRepositoryImpl implements NotificationRepository {
  final List<AppNotification> _notifications = [];
  final _incomingController = StreamController<AppNotification>.broadcast();

  @override
  Future<Either<Failure, Unit>> record(AppNotification notification) async {
    _notifications.insert(0, notification);
    _incomingController.add(notification);
    return right(unit);
  }

  @override
  Future<Either<Failure, List<AppNotification>>> getRecent({
    int limit = 50,
  }) async {
    return right(_notifications.take(limit).toList());
  }

  @override
  Future<Either<Failure, Unit>> markAsRead(String id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index == -1) return left(const NotFoundFailure());
    _notifications[index] = _notifications[index].copyWith(read: true);
    return right(unit);
  }

  @override
  Stream<AppNotification> watchIncoming() => _incomingController.stream;

  void dispose() {
    _incomingController.close();
  }
}
