import 'package:flutter_test/flutter_test.dart';
import 'package:juma_ui_crm/features/audit/domain/entities/audit_log_query.dart';

void main() {
  group('AuditLogQuery.copyWith', () {
    test('setting a field keeps the others untouched', () {
      const original = AuditLogQuery(
        action: 'company_created',
        offset: 20,
        limit: 10,
      );
      final updated = original.copyWith(entityType: 'companies');

      expect(updated.entityType, 'companies');
      expect(updated.action, 'company_created');
      expect(updated.offset, 20);
      expect(updated.limit, 10);
    });

    test(
      'the clearX flags null out a field regardless of what value is passed',
      () {
        const original = AuditLogQuery(actorId: 'user-1', action: 'x');
        final updated = original.copyWith(
          clearActorId: true,
          clearAction: true,
        );

        expect(updated.actorId, isNull);
        expect(updated.action, isNull);
      },
    );

    test('changing the search term does not reset an unrelated offset', () {
      const original = AuditLogQuery(offset: 40);
      final updated = original.copyWith(search: 'audit');

      expect(updated.search, 'audit');
      expect(updated.offset, 40);
    });

    test('two queries built the same way are equal', () {
      const a = AuditLogQuery(actorId: 'u1', offset: 0, limit: 20);
      const b = AuditLogQuery(actorId: 'u1', offset: 0, limit: 20);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });
  });
}
