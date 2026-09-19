import 'package:flutter_test/flutter_test.dart';
import 'package:juma_ui_crm/features/notifications/domain/entities/app_notification.dart';
import 'package:juma_ui_crm/features/notifications/domain/value_objects/notification_type.dart';

void main() {
  group('AppNotification', () {
    test('copyWith(read: true) only changes read, nothing else', () {
      final original = AppNotification(
        id: 'n1',
        type: NotificationType.warehouseShortage,
        title: 'title',
        body: 'body',
        createdAt: DateTime(2026, 7, 1),
        read: false,
      );
      final updated = original.copyWith(read: true);

      expect(updated.read, isTrue);
      expect(updated.id, original.id);
      expect(updated.type, original.type);
      expect(updated.title, original.title);
      expect(updated.body, original.body);
      expect(updated.createdAt, original.createdAt);
    });

    test('equality is based on id and read, not the rest', () {
      final a = AppNotification(
        id: 'n1',
        type: NotificationType.newOrder,
        title: 'A',
        body: 'A',
        createdAt: DateTime(2026),
      );
      final b = AppNotification(
        id: 'n1',
        type: NotificationType.newPayment,
        title: 'B',
        body: 'B',
        createdAt: DateTime(2027),
      );
      expect(a, equals(b));
    });
  });

  group('NotificationType', () {
    test('fromDbKey round-trips every value', () {
      for (final type in NotificationType.values) {
        expect(NotificationType.fromDbKey(type.dbKey), type);
      }
    });

    test('fromDbKey throws for an unknown key', () {
      expect(() => NotificationType.fromDbKey('bogus'), throwsArgumentError);
    });
  });
}
