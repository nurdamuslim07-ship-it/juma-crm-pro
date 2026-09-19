/// Pure QR-payload encode/decode (requirement: "QR" + "Barcode") — kept
/// out of widgets/providers so the payload format is directly
/// unit-testable, same convention as production_qr.dart.
library;

const _qrPrefix = 'juma-material:';
final _uuidPattern = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
);

/// The exact text encoded into a material's printed QR label — a
/// prefixed UUID so a scan of some unrelated QR code isn't misread as
/// a valid material id.
String encodeMaterialQrPayload(String materialId) => '$_qrPrefix$materialId';

/// Returns the material id if [payload] is a valid, well-formed
/// material QR payload, otherwise null.
String? decodeMaterialIdFromQrPayload(String payload) {
  if (!payload.startsWith(_qrPrefix)) return null;
  final id = payload.substring(_qrPrefix.length);
  if (!_uuidPattern.hasMatch(id)) return null;
  return id;
}

/// Requirement: "Barcode" + "QR" share one scanner screen — a scanned
/// code is first tried as a material QR payload; if that fails (most
/// scans will be a supplier's plain EAN/UPC barcode, not one of our
/// printed QR labels), the raw text is treated as a literal barcode
/// instead, resolved server-side via `get_material_id_by_barcode()`.
/// This returns which of the two the caller should do, never both.
sealed class ScanResult {
  const ScanResult();
}

class ScanResolvedMaterialId extends ScanResult {
  const ScanResolvedMaterialId(this.materialId);
  final String materialId;
}

class ScanBarcodeCandidate extends ScanResult {
  const ScanBarcodeCandidate(this.barcode);
  final String barcode;
}

ScanResult classifyScannedCode(String raw) {
  final materialId = decodeMaterialIdFromQrPayload(raw);
  if (materialId != null) return ScanResolvedMaterialId(materialId);
  return ScanBarcodeCandidate(raw);
}
