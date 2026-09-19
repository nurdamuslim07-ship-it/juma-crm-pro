import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/purchase_order_item.dart';

/// Local-only pending line items for the PO create/edit form (mirrors
/// Warehouse's `IssueCartNotifier`) — submitted wholesale via
/// `create_purchase_order()`/`update_purchase_order()`'s `p_items`
/// jsonb param, never written anywhere until then.
class PurchaseOrderDraftItemsNotifier
    extends StateNotifier<List<PurchaseOrderItem>> {
  PurchaseOrderDraftItemsNotifier() : super(const []);

  /// Populates the draft from an existing order's items when opening
  /// the edit form — called once, right after the sheet opens.
  void seed(List<PurchaseOrderItem> items) => state = items;

  void add(PurchaseOrderItem item) {
    final existingIndex = state.indexOf(item);
    if (existingIndex == -1) {
      state = [...state, item];
      return;
    }
    final existing = state[existingIndex];
    final updated = [...state];
    updated[existingIndex] = existing.copyWith(
      quantity: existing.quantity + item.quantity,
    );
    state = updated;
  }

  void updateItem(PurchaseOrderItem original, PurchaseOrderItem updated) {
    state = [
      for (final entry in state)
        if (entry == original) updated else entry,
    ];
  }

  void remove(PurchaseOrderItem item) {
    state = state.where((entry) => entry != item).toList();
  }

  void clear() => state = const [];
}

final purchaseOrderDraftItemsProvider =
    StateNotifierProvider.autoDispose<
      PurchaseOrderDraftItemsNotifier,
      List<PurchaseOrderItem>
    >((ref) => PurchaseOrderDraftItemsNotifier());
