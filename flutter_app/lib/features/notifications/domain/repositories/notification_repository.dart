import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/app_notification.dart';

/// The seam a future push-notification provider (Firebase Cloud
/// Messaging, APNS) plugs into — see [AppNotification]'s own doc
/// comment. This stage ships exactly one implementation
/// (`LocalNotificationRepositoryImpl`, in-memory, no persistence, no
/// remote delivery — "no provider integration yet" per the Stage 4
/// Part 2 ask); swapping in a real push provider later means writing
/// a second implementation of this SAME interface, not changing any
/// domain/presentation code that depends on it.
abstract class NotificationRepository {
  /// Records a notification and (for whatever implementation is
  /// current) makes it visible to [watchIncoming]/[getRecent]. A
  /// Firebase-backed implementation would additionally push this to
  /// the device's notification tray; the local one just stores it.
  Future<Either<Failure, Unit>> record(AppNotification notification);

  Future<Either<Failure, List<AppNotification>>> getRecent({int limit = 50});

  Future<Either<Failure, Unit>> markAsRead(String id);

  /// Emits each notification as it's recorded — the in-app equivalent
  /// of a push arriving, for whichever UI eventually wants to react
  /// live (a bell-icon badge, an in-app banner).
  Stream<AppNotification> watchIncoming();
}
