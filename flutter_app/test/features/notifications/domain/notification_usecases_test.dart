import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:juma_ui_crm/core/error/failures.dart';
import 'package:juma_ui_crm/features/notifications/domain/entities/app_notification.dart';
import 'package:juma_ui_crm/features/notifications/domain/repositories/notification_repository.dart';
import 'package:juma_ui_crm/features/notifications/domain/usecases/get_recent_notifications_usecase.dart';
import 'package:juma_ui_crm/features/notifications/domain/usecases/mark_notification_read_usecase.dart';
import 'package:juma_ui_crm/features/notifications/domain/usecases/record_notification_usecase.dart';
import 'package:juma_ui_crm/features/notifications/domain/value_objects/notification_type.dart';

/// Hand-written fake — same approach as every other repository test in
/// this codebase (no mocking framework exists).
class _FakeNotificationRepository implements NotificationRepository {
  Failure? failureToReturn;
  AppNotification? lastRecorded;
  String? lastMarkedReadId;

  @override
  Future<Either<Failure, Unit>> record(AppNotification notification) async {
    lastRecorded = notification;
    if (failureToReturn != null) return left(failureToReturn!);
    return right(unit);
  }

  @override
  Future<Either<Failure, List<AppNotification>>> getRecent({
    int limit = 50,
  }) async {
    if (failureToReturn != null) return left(failureToReturn!);
    return right(const []);
  }

  @override
  Future<Either<Failure, Unit>> markAsRead(String id) async {
    lastMarkedReadId = id;
    if (failureToReturn != null) return left(failureToReturn!);
    return right(unit);
  }

  @override
  Stream<AppNotification> watchIncoming() => const Stream.empty();
}

void main() {
  late _FakeNotificationRepository repository;

  setUp(() {
    repository = _FakeNotificationRepository();
  });

  test(
    'RecordNotificationUseCase passes the notification through unchanged',
    () async {
      final useCase = RecordNotificationUseCase(repository);
      final notification = AppNotification(
        id: 'n1',
        type: NotificationType.subscriptionExpiring,
        title: 'title',
        body: 'body',
        payload: const {'daysRemaining': 7},
        createdAt: DateTime(2026),
      );
      final result = await useCase(notification);

      expect(result.isRight(), isTrue);
      expect(repository.lastRecorded?.id, 'n1');
      expect(repository.lastRecorded?.payload['daysRemaining'], 7);
    },
  );

  test('GetRecentNotificationsUseCase returns the repository result', () async {
    final useCase = GetRecentNotificationsUseCase(repository);
    final result = await useCase();
    result.match(
      (_) => fail('expected right'),
      (list) => expect(list, isEmpty),
    );
  });

  test('MarkNotificationReadUseCase passes the id through', () async {
    final useCase = MarkNotificationReadUseCase(repository);
    await useCase('n1');
    expect(repository.lastMarkedReadId, 'n1');
  });

  test('a failure propagates through the usecase unchanged', () async {
    repository.failureToReturn = const NotFoundFailure();
    final useCase = MarkNotificationReadUseCase(repository);
    final result = await useCase('missing');
    result.match(
      (failure) => expect(failure, isA<NotFoundFailure>()),
      (_) => fail('expected left'),
    );
  });
}
