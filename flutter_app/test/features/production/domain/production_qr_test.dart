import 'package:flutter_test/flutter_test.dart';
import 'package:juma_ui_crm/features/production/domain/production_qr.dart';

void main() {
  group('encodeOrderQrPayload / decodeOrderIdFromQrPayload', () {
    const orderId = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';

    test('round-trips a valid order id through the QR payload', () {
      final payload = encodeOrderQrPayload(orderId);
      expect(decodeOrderIdFromQrPayload(payload), orderId);
    });

    test('rejects a payload without the "juma-order:" prefix — a '
        "stranger's QR code shouldn't be misread as a valid order", () {
      expect(decodeOrderIdFromQrPayload(orderId), isNull);
      expect(decodeOrderIdFromQrPayload('https://example.com'), isNull);
    });

    test('rejects a prefixed payload whose id is not a well-formed UUID', () {
      expect(decodeOrderIdFromQrPayload('juma-order:not-a-uuid'), isNull);
    });

    test('rejects an empty scan', () {
      expect(decodeOrderIdFromQrPayload(''), isNull);
    });
  });

  group('computeTimeLogDuration', () {
    test('measures a closed log by its own start/end', () {
      final duration = computeTimeLogDuration(
        startedAt: DateTime(2026, 7, 13, 9, 0),
        endedAt: DateTime(2026, 7, 13, 11, 30),
        now: DateTime(2026, 7, 13, 15, 0),
      );
      expect(duration, const Duration(hours: 2, minutes: 30));
    });

    test('measures an open log against "now", not a fixed end', () {
      final duration = computeTimeLogDuration(
        startedAt: DateTime(2026, 7, 13, 9, 0),
        now: DateTime(2026, 7, 13, 9, 45),
      );
      expect(duration, const Duration(minutes: 45));
    });
  });
}
