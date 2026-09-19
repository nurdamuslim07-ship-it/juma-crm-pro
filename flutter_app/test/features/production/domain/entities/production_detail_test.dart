import 'package:flutter_test/flutter_test.dart';
import 'package:juma_ui_crm/features/production/domain/entities/material_availability.dart';
import 'package:juma_ui_crm/features/production/domain/entities/production_detail.dart';

ProductionDetail _detail({List<MaterialAvailability> materials = const []}) {
  return ProductionDetail(
    orderId: 'o1',
    orderNumber: 'JU-0001',
    productType: 'Шкаф',
    clientName: 'Асқар',
    stageId: 's1',
    stageKey: 'cutting',
    stageNameKk: 'Кесу',
    percentComplete: 15,
    materials: materials,
  );
}

void main() {
  group('ProductionDetail.allMaterialsSufficient', () {
    test('is true when there are no reserved materials at all', () {
      expect(_detail().allMaterialsSufficient, isTrue);
    });

    test('is true when every reserved material is sufficient', () {
      final detail = _detail(
        materials: const [
          MaterialAvailability(
            materialName: 'ЛДСП',
            unit: 'парақ',
            reservedQuantity: 5,
            availableQuantity: 10,
            isSufficient: true,
          ),
        ],
      );
      expect(detail.allMaterialsSufficient, isTrue);
    });

    test('is false when any one reserved material is insufficient', () {
      final detail = _detail(
        materials: const [
          MaterialAvailability(
            materialName: 'ЛДСП',
            unit: 'парақ',
            reservedQuantity: 5,
            availableQuantity: 10,
            isSufficient: true,
          ),
          MaterialAvailability(
            materialName: 'Фурнитура',
            unit: 'дана',
            reservedQuantity: 20,
            availableQuantity: 4,
            isSufficient: false,
          ),
        ],
      );
      expect(detail.allMaterialsSufficient, isFalse);
    });
  });
}
