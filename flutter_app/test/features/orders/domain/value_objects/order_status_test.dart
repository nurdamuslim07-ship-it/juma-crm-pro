import 'package:flutter_test/flutter_test.dart';
import 'package:juma_ui_crm/features/orders/domain/value_objects/order_status.dart';

void main() {
  group('OrderStatus.dbValue / fromDbValue', () {
    test('round-trips every status through its Postgres enum key', () {
      for (final status in OrderStatus.values) {
        expect(OrderStatus.fromDbValue(status.dbValue), status);
      }
    });

    test('matches the exact keys defined in the order_status Postgres enum '
        '(supabase/migrations/20260713000001_extensions_and_enums.sql)', () {
      expect(OrderStatus.measurement.dbValue, 'measurement');
      expect(OrderStatus.accepted.dbValue, 'accepted');
      expect(OrderStatus.inProgress.dbValue, 'in_progress');
      expect(OrderStatus.ready.dbValue, 'ready');
      expect(OrderStatus.installed.dbValue, 'installed');
    });

    test('throws on an unknown value instead of silently returning null', () {
      expect(() => OrderStatus.fromDbValue('cancelled'), throwsArgumentError);
    });
  });
}
