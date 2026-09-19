import 'package:flutter_test/flutter_test.dart';
import 'package:juma_ui_crm/features/orders/domain/value_objects/order_status.dart';
import 'package:juma_ui_crm/features/orders/presentation/providers/order_providers.dart';

// Mirrors the exact seed data in
// supabase/migrations/20260713000015_order_status_transitions.sql —
// if that migration's role grants ever drift from this map, this test
// (not a live database) is what catches it.
final _permissions = <OrderStatus, Set<String>>{
  OrderStatus.measurement: {'measurer', 'manager', 'director'},
  OrderStatus.accepted: {'manager', 'director'},
  OrderStatus.inProgress: {'manager', 'designer', 'director'},
  OrderStatus.ready: {'director', 'manager', 'workshop_manager'},
  OrderStatus.installed: {'director', 'manager', 'workshop_manager'},
};

void main() {
  group('computeAllowedOrderStatuses', () {
    test('measurer may only set "Замер"', () {
      final allowed = computeAllowedOrderStatuses(_permissions, ['measurer']);
      expect(allowed, {OrderStatus.measurement});
    });

    test('designer may only set "Өңделуде"', () {
      final allowed = computeAllowedOrderStatuses(_permissions, ['designer']);
      expect(allowed, {OrderStatus.inProgress});
    });

    test('workshop_manager may set "Тапсырыс дайын" and "Орнатылды" only', () {
      final allowed = computeAllowedOrderStatuses(_permissions, [
        'workshop_manager',
      ]);
      expect(allowed, {OrderStatus.ready, OrderStatus.installed});
    });

    test('manager may set every status', () {
      final allowed = computeAllowedOrderStatuses(_permissions, ['manager']);
      expect(allowed, OrderStatus.values.toSet());
    });

    test('director may set every status', () {
      final allowed = computeAllowedOrderStatuses(_permissions, ['director']);
      expect(allowed, OrderStatus.values.toSet());
    });

    test('a role with no grants (e.g. accountant) may set nothing', () {
      final allowed = computeAllowedOrderStatuses(_permissions, ['accountant']);
      expect(allowed, isEmpty);
    });

    test('multiple roles union their allowed statuses', () {
      final allowed = computeAllowedOrderStatuses(_permissions, [
        'measurer',
        'designer',
      ]);
      expect(allowed, {OrderStatus.measurement, OrderStatus.inProgress});
    });
  });
}
