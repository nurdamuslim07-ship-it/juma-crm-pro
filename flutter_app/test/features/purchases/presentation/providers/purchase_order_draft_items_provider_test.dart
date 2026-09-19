import 'package:flutter_test/flutter_test.dart';
import 'package:juma_ui_crm/features/purchases/domain/entities/purchase_order_item.dart';
import 'package:juma_ui_crm/features/purchases/presentation/providers/purchase_order_draft_items_provider.dart';

void main() {
  const itemA = PurchaseOrderItem(
    materialId: 'm1',
    materialName: 'ЛДСП 16мм',
    quantity: 20,
    unit: 'парақ',
    unitPriceTiyn: 850000,
    locationId: 'l1',
    locationName: 'Сөре 1',
  );

  test('starts empty', () {
    final notifier = PurchaseOrderDraftItemsNotifier();
    expect(notifier.state, isEmpty);
  });

  test('add() appends a new material+location combination', () {
    final notifier = PurchaseOrderDraftItemsNotifier();
    notifier.add(itemA);
    expect(notifier.state, [itemA]);
  });

  test('add() merges quantities for the same material+location', () {
    final notifier = PurchaseOrderDraftItemsNotifier();
    notifier.add(itemA);
    notifier.add(itemA.copyWith(quantity: 5));
    expect(notifier.state, hasLength(1));
    expect(notifier.state.single.quantity, 25);
  });

  test('updateItem() replaces a matching entry entirely', () {
    final notifier = PurchaseOrderDraftItemsNotifier();
    notifier.add(itemA);
    final updated = itemA.copyWith(quantity: 100, unitPriceTiyn: 1);
    notifier.updateItem(itemA, updated);
    expect(notifier.state.single.quantity, 100);
    expect(notifier.state.single.unitPriceTiyn, 1);
  });

  test('remove() drops the matching entry', () {
    final notifier = PurchaseOrderDraftItemsNotifier();
    notifier.add(itemA);
    notifier.remove(itemA);
    expect(notifier.state, isEmpty);
  });

  test('clear() empties the draft', () {
    final notifier = PurchaseOrderDraftItemsNotifier();
    notifier.add(itemA);
    notifier.clear();
    expect(notifier.state, isEmpty);
  });

  test('seed() replaces the whole draft (used when opening the edit form)', () {
    final notifier = PurchaseOrderDraftItemsNotifier();
    notifier.add(itemA);
    const seeded = [
      PurchaseOrderItem(
        materialId: 'm2',
        quantity: 3,
        unit: 'дана',
        unitPriceTiyn: 500,
        locationId: 'l2',
      ),
    ];
    notifier.seed(seeded);
    expect(notifier.state, seeded);
  });
}
