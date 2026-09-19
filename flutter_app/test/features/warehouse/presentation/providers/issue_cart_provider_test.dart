import 'package:flutter_test/flutter_test.dart';
import 'package:juma_ui_crm/features/warehouse/domain/entities/cart_item.dart';
import 'package:juma_ui_crm/features/warehouse/presentation/providers/issue_cart_provider.dart';

void main() {
  const itemA = CartItem(
    materialId: 'm1',
    materialName: 'ЛДСП 16мм',
    locationId: 'l1',
    locationName: 'Сөре 1',
    unit: 'парақ',
    quantity: 2,
  );

  test('starts empty', () {
    final notifier = IssueCartNotifier();
    expect(notifier.state, isEmpty);
  });

  test('add() appends a new material+location combination', () {
    final notifier = IssueCartNotifier();
    notifier.add(itemA);
    expect(notifier.state, [itemA]);
  });

  test('add() merges quantities for the same material+location', () {
    final notifier = IssueCartNotifier();
    notifier.add(itemA);
    notifier.add(itemA.copyWith(quantity: 3));
    expect(notifier.state, hasLength(1));
    expect(notifier.state.single.quantity, 5);
  });

  test('updateQuantity() replaces the quantity of a matching entry', () {
    final notifier = IssueCartNotifier();
    notifier.add(itemA);
    notifier.updateQuantity(itemA, 10);
    expect(notifier.state.single.quantity, 10);
  });

  test('remove() drops the matching entry', () {
    final notifier = IssueCartNotifier();
    notifier.add(itemA);
    notifier.remove(itemA);
    expect(notifier.state, isEmpty);
  });

  test('clear() empties the cart', () {
    final notifier = IssueCartNotifier();
    notifier.add(itemA);
    notifier.clear();
    expect(notifier.state, isEmpty);
  });
}
