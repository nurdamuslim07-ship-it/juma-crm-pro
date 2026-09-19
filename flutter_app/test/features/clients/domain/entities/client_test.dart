import 'package:flutter_test/flutter_test.dart';
import 'package:juma_ui_crm/features/clients/domain/entities/client.dart';

void main() {
  group('Client', () {
    test(
      'equality is based on id only, matching the persisted-row identity',
      () {
        final a = Client(
          id: '1',
          name: 'Асқар',
          phone: '+7...',
          createdAt: DateTime(2026),
        );
        final b = Client(
          id: '1',
          name: 'Басқа атау',
          phone: '+7...',
          createdAt: DateTime(2026),
        );
        expect(a, equals(b));
      },
    );

    test('copyWith only overrides the provided fields', () {
      final original = Client(
        id: '1',
        name: 'Асқар',
        phone: '+77011234567',
        city: 'Алматы',
        createdAt: DateTime(2026),
      );

      final updated = original.copyWith(city: 'Астана');

      expect(updated.city, 'Астана');
      expect(updated.name, 'Асқар');
      expect(updated.phone, '+77011234567');
      expect(updated.id, '1');
    });
  });
}
