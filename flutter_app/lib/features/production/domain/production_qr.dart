/// Pure QR-payload encode/decode + time-log duration math (requirement:
/// "QR код арқылы тапсырысты ашу" + "Уақыт журналдары") — kept out of
/// widgets/providers so the payload format and elapsed-time rule are
/// directly unit-testable, same convention as every other module's
/// domain-layer pure functions (e.g. payment_rules.dart).
library;

const _qrPrefix = 'juma-order:';
final _uuidPattern = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
);

/// The exact text encoded into the QR shown/printed for an order — a
/// prefixed UUID rather than a bare one, so a scan of some unrelated
/// QR code (e.g. a supplier's barcode) doesn't get misread as a valid
/// order id.
String encodeOrderQrPayload(String orderId) => '$_qrPrefix$orderId';

/// Returns the order id if [payload] is a valid, well-formed order QR
/// payload, otherwise null (a stranger's QR code, garbage scan data,
/// or a payload missing the prefix).
String? decodeOrderIdFromQrPayload(String payload) {
  if (!payload.startsWith(_qrPrefix)) return null;
  final id = payload.substring(_qrPrefix.length);
  if (!_uuidPattern.hasMatch(id)) return null;
  return id;
}

/// Elapsed time for a time log — [now] is passed in (rather than read
/// via `DateTime.now()` here) so this stays a pure, deterministic
/// function; an open log's duration is measured against [now].
Duration computeTimeLogDuration({
  required DateTime startedAt,
  DateTime? endedAt,
  required DateTime now,
}) {
  return (endedAt ?? now).difference(startedAt);
}
