import 'package:flutter_test/flutter_test.dart';
import 'package:juma_ui_crm/features/warehouse/domain/warehouse_qr.dart';

void main() {
  group('encodeMaterialQrPayload / decodeMaterialIdFromQrPayload', () {
    const materialId = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';

    test('round-trips a valid material id through the QR payload', () {
      final payload = encodeMaterialQrPayload(materialId);
      expect(decodeMaterialIdFromQrPayload(payload), materialId);
    });

    test('rejects a payload without the "juma-material:" prefix — a '
        "supplier's plain barcode shouldn't be misread as a material QR", () {
      expect(decodeMaterialIdFromQrPayload(materialId), isNull);
      expect(decodeMaterialIdFromQrPayload('4600000000011'), isNull);
    });

    test('rejects a prefixed payload whose id is not a well-formed UUID', () {
      expect(decodeMaterialIdFromQrPayload('juma-material:not-a-uuid'), isNull);
    });

    test('rejects an empty scan', () {
      expect(decodeMaterialIdFromQrPayload(''), isNull);
    });
  });

  group('classifyScannedCode', () {
    const materialId = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';

    test('a material QR payload resolves directly to a material id', () {
      final result = classifyScannedCode(encodeMaterialQrPayload(materialId));
      expect(result, isA<ScanResolvedMaterialId>());
      expect((result as ScanResolvedMaterialId).materialId, materialId);
    });

    test('a plain EAN barcode falls back to a barcode candidate', () {
      final result = classifyScannedCode('4600000000011');
      expect(result, isA<ScanBarcodeCandidate>());
      expect((result as ScanBarcodeCandidate).barcode, '4600000000011');
    });
  });
}
