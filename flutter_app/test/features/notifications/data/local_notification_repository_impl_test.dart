import 'package:flutter_test/flutter_test.dart';
import 'package:juma_ui_crm/features/notifications/data/repositories/local_notification_repository_impl.dart';
import 'package:juma_ui_crm/features/notifications/domain/entities/app_notification.dart';
import 'package:juma_ui_crm/features/notifications/domain/value_objects/notification_type.dart';

AppNotification _notification({String id = 'n1', bool read = false}) {
  return AppNotification(
    id: id,
    type: NotificationType.newOrder,
    title: 'Жаңа тапсырыс',
    body: 'JU-0001',
    createdAt: DateTime(2026, 7, 1),
    read: read,
  );
}

void main() {
  late LocalNotificationRepositoryImpl repository;

  setUp(() {
    repository = LocalNotificationRepositoryImpl();
  });

  tearDown(() {
    repository.dispose();
  });

  test('record() makes the notification visible via getRecent()', () async {
    await repository.record(_notification());
    final result = await repository.getRecent();
    result.match((_) => fail('expected right'), (list) {
      expect(list, hasLength(1));
      expect(list.first.id, 'n1');
    });
  });

  test('record() inserts newest-first', () async {
    await repository.record(_notification(id: 'n1'));
    await repository.record(_notification(id: 'n2'));
    final result = await repository.getRecent();
    result.match(
      (_) => fail('expected right'),
      (list) => expect(list.map((n) => n.id), ['n2', 'n1']),
    );
  });

  test('getRecent() respects the limit', () async {
    for (var i = 0; i < 5; i++) {
      await repository.record(_notification(id: 'n$i'));
    }
    final result = await repository.getRecent(limit: 2);
    result.match(
      (_) => fail('expected right'),
      (list) => expect(list, hasLength(2)),
    );
  });

  test('markAsRead() flips read on the matching notification only', () async {
    await repository.record(_notification(id: 'n1'));
    await repository.record(_notification(id: 'n2'));
    await repository.markAsRead('n1');

    final result = await repository.getRecent();
    result.match((_) => fail('expected right'), (list) {
      final n1 = list.firstWhere((n) => n.id == 'n1');
      final n2 = list.firstWhere((n) => n.id == 'n2');
      expect(n1.read, isTrue);
      expect(n2.read, isFalse);
    });
  });

  test('markAsRead() on an unknown id returns NotFoundFailure', () async {
    final result = await repository.markAsRead('unknown');
    expect(result.isLeft(), isTrue);
  });

  test('watchIncoming() emits every recorded notification live', () async {
    final emitted = <AppNotification>[];
    final subscription = repository.watchIncoming().listen(emitted.add);

    await repository.record(_notification(id: 'n1'));
    await repository.record(_notification(id: 'n2'));
    await Future<void>.delayed(Duration.zero);

    expect(emitted.map((n) => n.id), ['n1', 'n2']);
    await subscription.cancel();
  });
}
