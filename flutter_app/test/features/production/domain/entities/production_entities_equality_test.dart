import 'package:flutter_test/flutter_test.dart';
import 'package:juma_ui_crm/features/production/domain/entities/production_master.dart';
import 'package:juma_ui_crm/features/production/domain/entities/production_photo.dart';
import 'package:juma_ui_crm/features/production/domain/entities/production_queue_item.dart';
import 'package:juma_ui_crm/features/production/domain/entities/production_stage.dart';

void main() {
  group('ProductionStage equality', () {
    test('is based on id only', () {
      const a = ProductionStage(
        id: 's1',
        key: 'cutting',
        nameKk: 'Кесу',
        sortOrder: 2,
        defaultPercent: 15,
      );
      const b = ProductionStage(
        id: 's1',
        key: 'painting',
        nameKk: 'Бояу',
        sortOrder: 5,
        defaultPercent: 60,
      );
      expect(a, equals(b));
    });

    test('different ids are not equal', () {
      const a = ProductionStage(
        id: 's1',
        key: 'cutting',
        nameKk: 'Кесу',
        sortOrder: 2,
        defaultPercent: 15,
      );
      const b = ProductionStage(
        id: 's2',
        key: 'cutting',
        nameKk: 'Кесу',
        sortOrder: 2,
        defaultPercent: 15,
      );
      expect(a, isNot(equals(b)));
    });
  });

  test('ProductionQueueItem equality is based on orderId only', () {
    final a = ProductionQueueItem(
      orderId: 'o1',
      orderNumber: 'JU-0001',
      productType: 'Шкаф',
      clientName: 'Асқар',
      stageId: 's1',
      stageKey: 'cutting',
      stageNameKk: 'Кесу',
      stageSortOrder: 2,
      percentComplete: 15,
      materialsSufficient: true,
      photosCount: 0,
      updatedAt: DateTime(2026, 7, 13),
    );
    final b = ProductionQueueItem(
      orderId: 'o1',
      orderNumber: 'JU-9999',
      productType: 'Үстел',
      clientName: 'Мадина',
      stageId: 's9',
      stageKey: 'ready',
      stageNameKk: 'Дайын',
      stageSortOrder: 7,
      percentComplete: 90,
      materialsSufficient: false,
      photosCount: 3,
      updatedAt: DateTime(2026, 7, 14),
    );
    expect(a, equals(b));
  });

  test('ProductionMaster equality is based on userId only', () {
    const a = ProductionMaster(userId: 'u1', fullName: 'Асқар');
    const b = ProductionMaster(userId: 'u1', fullName: 'Мадина');
    expect(a, equals(b));
    const c = ProductionMaster(userId: 'u2', fullName: 'Асқар');
    expect(a, isNot(equals(c)));
  });

  test('ProductionPhoto equality is based on id only', () {
    final a = ProductionPhoto(
      id: 'p1',
      storagePath: 'o1/1.jpg',
      uploadedAt: DateTime(2026, 7, 13),
    );
    final b = ProductionPhoto(
      id: 'p1',
      storagePath: 'o1/2.jpg',
      uploadedAt: DateTime(2026, 7, 14),
    );
    expect(a, equals(b));
  });
}
