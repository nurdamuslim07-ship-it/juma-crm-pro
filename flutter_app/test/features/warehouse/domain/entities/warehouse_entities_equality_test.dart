import 'package:flutter_test/flutter_test.dart';
import 'package:juma_ui_crm/features/warehouse/domain/entities/cart_item.dart';
import 'package:juma_ui_crm/features/warehouse/domain/entities/inventory_batch.dart';
import 'package:juma_ui_crm/features/warehouse/domain/entities/inventory_hold.dart';
import 'package:juma_ui_crm/features/warehouse/domain/entities/material_category.dart';
import 'package:juma_ui_crm/features/warehouse/domain/entities/material_stock.dart';
import 'package:juma_ui_crm/features/warehouse/domain/entities/warehouse_location.dart';

void main() {
  test('MaterialCategory equality is based on id only', () {
    const a = MaterialCategory(id: 'c1', key: 'ldsp', nameKk: 'ЛДСП');
    const b = MaterialCategory(id: 'c1', key: 'mdf', nameKk: 'МДФ');
    expect(a, equals(b));
    const c = MaterialCategory(id: 'c2', key: 'ldsp', nameKk: 'ЛДСП');
    expect(a, isNot(equals(c)));
  });

  test('WarehouseLocation equality is based on id only', () {
    const a = WarehouseLocation(id: 'l1', warehouseId: 'w1', name: 'Сөре 1');
    const b = WarehouseLocation(id: 'l1', warehouseId: 'w2', name: 'Сөре 2');
    expect(a, equals(b));
  });

  test('MaterialStock equality is based on materialId only', () {
    const a = MaterialStock(
      materialId: 'm1',
      name: 'ЛДСП 16мм',
      unit: 'парақ',
      minQuantity: 5,
      costPerUnitTiyn: 850000,
      totalQuantity: 20,
      totalReserved: 5,
      availableQuantity: 15,
      isLowStock: false,
    );
    const b = MaterialStock(
      materialId: 'm1',
      name: 'МДФ 18мм',
      unit: 'парақ',
      minQuantity: 3,
      costPerUnitTiyn: 920000,
      totalQuantity: 1,
      totalReserved: 0,
      availableQuantity: 1,
      isLowStock: true,
    );
    expect(a, equals(b));
    const c = MaterialStock(
      materialId: 'm2',
      name: 'ЛДСП 16мм',
      unit: 'парақ',
      minQuantity: 5,
      costPerUnitTiyn: 850000,
      totalQuantity: 20,
      totalReserved: 5,
      availableQuantity: 15,
      isLowStock: false,
    );
    expect(a, isNot(equals(c)));
  });

  test('InventoryBatch equality is based on id only', () {
    final a = InventoryBatch(
      id: 'b1',
      materialId: 'm1',
      locationId: 'l1',
      quantityReceived: 20,
      quantityRemaining: 20,
      costPerUnitTiyn: 850000,
      receivedAt: DateTime(2026, 7, 13),
    );
    final b = InventoryBatch(
      id: 'b1',
      materialId: 'm2',
      locationId: 'l2',
      quantityReceived: 5,
      quantityRemaining: 1,
      costPerUnitTiyn: 100,
      receivedAt: DateTime(2026, 7, 14),
    );
    expect(a, equals(b));
  });

  test(
    'InventoryHold equality is based on id only, isActive reflects releasedAt',
    () {
      final active = InventoryHold(
        id: 'h1',
        materialId: 'm1',
        locationId: 'l1',
        quantity: 1,
        createdAt: DateTime(2026, 7, 13),
      );
      final released = InventoryHold(
        id: 'h1',
        materialId: 'm1',
        locationId: 'l1',
        quantity: 1,
        createdAt: DateTime(2026, 7, 13),
        releasedAt: DateTime(2026, 7, 14),
      );
      expect(active, equals(released));
      expect(active.isActive, isTrue);
      expect(released.isActive, isFalse);
    },
  );

  test(
    'CartItem equality is based on materialId + locationId, not quantity',
    () {
      const a = CartItem(
        materialId: 'm1',
        materialName: 'ЛДСП',
        locationId: 'l1',
        locationName: 'Сөре 1',
        unit: 'парақ',
        quantity: 2,
      );
      const b = CartItem(
        materialId: 'm1',
        materialName: 'ЛДСП',
        locationId: 'l1',
        locationName: 'Сөре 1',
        unit: 'парақ',
        quantity: 9,
      );
      expect(a, equals(b));

      const differentLocation = CartItem(
        materialId: 'm1',
        materialName: 'ЛДСП',
        locationId: 'l2',
        locationName: 'Сөре 2',
        unit: 'парақ',
        quantity: 2,
      );
      expect(a, isNot(equals(differentLocation)));
    },
  );

  test('CartItem.copyWith replaces only the quantity', () {
    const item = CartItem(
      materialId: 'm1',
      materialName: 'ЛДСП',
      locationId: 'l1',
      locationName: 'Сөре 1',
      unit: 'парақ',
      quantity: 2,
    );
    final updated = item.copyWith(quantity: 7);
    expect(updated.quantity, 7);
    expect(updated.materialId, item.materialId);
  });
}
