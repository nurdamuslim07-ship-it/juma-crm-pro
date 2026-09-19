import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/cart_item.dart';

/// Requirement: "Себетке шығару" — local-only pending state, cleared
/// once `issue_materials()` submits it atomically (see
/// `issue_cart_sheet.dart`). Never persisted; a cart that's abandoned
/// mid-way simply resets on next screen visit.
class IssueCartNotifier extends StateNotifier<List<CartItem>> {
  IssueCartNotifier() : super(const []);

  void add(CartItem item) {
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

  void updateQuantity(CartItem item, num quantity) {
    state = [
      for (final entry in state)
        if (entry == item) entry.copyWith(quantity: quantity) else entry,
    ];
  }

  void remove(CartItem item) {
    state = state.where((entry) => entry != item).toList();
  }

  void clear() => state = const [];
}

final issueCartProvider =
    StateNotifierProvider.autoDispose<IssueCartNotifier, List<CartItem>>(
      (ref) => IssueCartNotifier(),
    );
