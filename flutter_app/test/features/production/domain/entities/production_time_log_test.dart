import 'package:flutter_test/flutter_test.dart';
import 'package:juma_ui_crm/features/production/domain/entities/production_time_log.dart';

void main() {
  test('isOpen is true when endedAt is null', () {
    final log = ProductionTimeLog(
      employeeId: 'e1',
      employeeName: 'Асқар',
      startedAt: DateTime(2026, 7, 13, 9),
    );
    expect(log.isOpen, isTrue);
  });

  test('isOpen is false once endedAt is set', () {
    final log = ProductionTimeLog(
      employeeId: 'e1',
      employeeName: 'Асқар',
      startedAt: DateTime(2026, 7, 13, 9),
      endedAt: DateTime(2026, 7, 13, 10),
    );
    expect(log.isOpen, isFalse);
  });
}
