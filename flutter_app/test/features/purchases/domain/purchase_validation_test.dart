import 'package:flutter_test/flutter_test.dart';
import 'package:juma_ui_crm/features/purchases/domain/entities/purchase_order_item.dart';
import 'package:juma_ui_crm/features/purchases/domain/entities/purchase_order_status.dart';
import 'package:juma_ui_crm/features/purchases/domain/purchase_validation.dart';

void main() {
  group('validateSupplierSelected', () {
    test('rejects null and empty/whitespace supplier ids', () {
      expect(validateSupplierSelected(null), isNotNull);
      expect(validateSupplierSelected(''), isNotNull);
      expect(validateSupplierSelected('   '), isNotNull);
    });

    test('accepts a non-empty supplier id', () {
      expect(validateSupplierSelected('s1'), isNull);
    });
  });

  group('validateHasItems', () {
    test('rejects zero items', () {
      expect(validateHasItems(0), isNotNull);
    });

    test('accepts at least one item', () {
      expect(validateHasItems(1), isNull);
    });
  });

  group('validateItemQuantity', () {
    test('rejects zero and negative quantities', () {
      expect(validateItemQuantity(0), isNotNull);
      expect(validateItemQuantity(-5), isNotNull);
    });

    test('accepts a positive quantity', () {
      expect(validateItemQuantity(2.5), isNull);
    });
  });

  group('validateItemUnitPriceTiyn', () {
    test('rejects a negative unit price', () {
      expect(validateItemUnitPriceTiyn(-1), isNotNull);
    });

    test('accepts zero and positive unit prices', () {
      expect(validateItemUnitPriceTiyn(0), isNull);
      expect(validateItemUnitPriceTiyn(100), isNull);
    });
  });

  group('validateNonNegativeAdjustmentTiyn', () {
    test('rejects a negative amount', () {
      expect(validateNonNegativeAdjustmentTiyn(-1, 'ҚҚС'), isNotNull);
    });

    test('accepts zero and positive amounts', () {
      expect(validateNonNegativeAdjustmentTiyn(0, 'ҚҚС'), isNull);
      expect(validateNonNegativeAdjustmentTiyn(500, 'ҚҚС'), isNull);
    });
  });

  group('validateReceivedQuantity', () {
    test('rejects a received quantity above the ordered quantity', () {
      expect(
        validateReceivedQuantity(receivedQuantity: 11, orderedQuantity: 10),
        isNotNull,
      );
    });

    test('accepts a received quantity at or below the ordered quantity', () {
      expect(
        validateReceivedQuantity(receivedQuantity: 10, orderedQuantity: 10),
        isNull,
      );
      expect(
        validateReceivedQuantity(receivedQuantity: 5, orderedQuantity: 10),
        isNull,
      );
    });
  });

  group('validatePaymentAmount', () {
    test('rejects zero and negative amounts', () {
      expect(validatePaymentAmount(amountTiyn: 0), isNotNull);
      expect(validatePaymentAmount(amountTiyn: -1), isNotNull);
    });

    test(
      'rejects an amount above the invoice remaining when tied to an invoice',
      () {
        expect(
          validatePaymentAmount(amountTiyn: 1001, invoiceRemainingTiyn: 1000),
          isNotNull,
        );
      },
    );

    test('accepts an amount at or below the invoice remaining', () {
      expect(
        validatePaymentAmount(amountTiyn: 1000, invoiceRemainingTiyn: 1000),
        isNull,
      );
      expect(
        validatePaymentAmount(amountTiyn: 500, invoiceRemainingTiyn: 1000),
        isNull,
      );
    });

    test('has no upper bound for a reason-less advance (no invoice tied)', () {
      expect(validatePaymentAmount(amountTiyn: 999999999), isNull);
    });
  });

  group('isTerminalStatus / validateNotTerminal', () {
    test('received, rejected and cancelled are terminal', () {
      expect(isTerminalStatus(PurchaseOrderStatus.received), isTrue);
      expect(isTerminalStatus(PurchaseOrderStatus.rejected), isTrue);
      expect(isTerminalStatus(PurchaseOrderStatus.cancelled), isTrue);
    });

    test('draft, approved and delivered are not terminal', () {
      expect(isTerminalStatus(PurchaseOrderStatus.draft), isFalse);
      expect(isTerminalStatus(PurchaseOrderStatus.approved), isFalse);
      expect(isTerminalStatus(PurchaseOrderStatus.delivered), isFalse);
    });

    test('validateNotTerminal rejects a terminal status', () {
      expect(validateNotTerminal(PurchaseOrderStatus.received), isNotNull);
    });

    test('validateNotTerminal accepts a non-terminal status', () {
      expect(validateNotTerminal(PurchaseOrderStatus.draft), isNull);
    });
  });

  group('canTransitionPurchaseOrderStatus / validateStatusTransition', () {
    const validTransitions = [
      (PurchaseOrderStatus.draft, PurchaseOrderStatus.approved),
      (PurchaseOrderStatus.draft, PurchaseOrderStatus.rejected),
      (PurchaseOrderStatus.approved, PurchaseOrderStatus.rejected),
      (PurchaseOrderStatus.approved, PurchaseOrderStatus.delivered),
      (PurchaseOrderStatus.delivered, PurchaseOrderStatus.received),
      (PurchaseOrderStatus.draft, PurchaseOrderStatus.cancelled),
      (PurchaseOrderStatus.approved, PurchaseOrderStatus.cancelled),
      (PurchaseOrderStatus.delivered, PurchaseOrderStatus.cancelled),
    ];

    for (final (from, to) in validTransitions) {
      test('allows $from -> $to', () {
        expect(canTransitionPurchaseOrderStatus(from, to), isTrue);
        expect(validateStatusTransition(from, to), isNull);
      });
    }

    const invalidTransitions = [
      (PurchaseOrderStatus.draft, PurchaseOrderStatus.delivered),
      (PurchaseOrderStatus.draft, PurchaseOrderStatus.received),
      (PurchaseOrderStatus.approved, PurchaseOrderStatus.received),
      (PurchaseOrderStatus.delivered, PurchaseOrderStatus.approved),
      (PurchaseOrderStatus.received, PurchaseOrderStatus.cancelled),
      (PurchaseOrderStatus.rejected, PurchaseOrderStatus.approved),
      (PurchaseOrderStatus.cancelled, PurchaseOrderStatus.draft),
    ];

    for (final (from, to) in invalidTransitions) {
      test('rejects $from -> $to', () {
        expect(canTransitionPurchaseOrderStatus(from, to), isFalse);
        expect(validateStatusTransition(from, to), isNotNull);
      });
    }

    test('nothing transitions back into draft', () {
      for (final from in PurchaseOrderStatus.values) {
        expect(
          canTransitionPurchaseOrderStatus(from, PurchaseOrderStatus.draft),
          isFalse,
        );
      }
    });
  });

  group('validatePurchaseOrderInput', () {
    const validItem = PurchaseOrderItem(
      materialId: 'm1',
      quantity: 5,
      unit: 'парақ',
      unitPriceTiyn: 100,
      locationId: 'l1',
    );

    test('rejects a missing supplier', () {
      expect(
        validatePurchaseOrderInput(
          supplierPartnerId: null,
          items: const [validItem],
          deliveryCostTiyn: 0,
          vatTiyn: 0,
          discountTiyn: 0,
        ),
        isNotNull,
      );
    });

    test('rejects an empty item list', () {
      expect(
        validatePurchaseOrderInput(
          supplierPartnerId: 's1',
          items: const [],
          deliveryCostTiyn: 0,
          vatTiyn: 0,
          discountTiyn: 0,
        ),
        isNotNull,
      );
    });

    test('rejects an item with a non-positive quantity', () {
      const badItem = PurchaseOrderItem(
        materialId: 'm1',
        quantity: 0,
        unit: 'парақ',
        unitPriceTiyn: 100,
        locationId: 'l1',
      );
      expect(
        validatePurchaseOrderInput(
          supplierPartnerId: 's1',
          items: const [badItem],
          deliveryCostTiyn: 0,
          vatTiyn: 0,
          discountTiyn: 0,
        ),
        isNotNull,
      );
    });

    test('rejects an item with a negative unit price', () {
      const badItem = PurchaseOrderItem(
        materialId: 'm1',
        quantity: 5,
        unit: 'парақ',
        unitPriceTiyn: -1,
        locationId: 'l1',
      );
      expect(
        validatePurchaseOrderInput(
          supplierPartnerId: 's1',
          items: const [badItem],
          deliveryCostTiyn: 0,
          vatTiyn: 0,
          discountTiyn: 0,
        ),
        isNotNull,
      );
    });

    test('rejects negative delivery/VAT/discount adjustments', () {
      expect(
        validatePurchaseOrderInput(
          supplierPartnerId: 's1',
          items: const [validItem],
          deliveryCostTiyn: -1,
          vatTiyn: 0,
          discountTiyn: 0,
        ),
        isNotNull,
      );
      expect(
        validatePurchaseOrderInput(
          supplierPartnerId: 's1',
          items: const [validItem],
          deliveryCostTiyn: 0,
          vatTiyn: -1,
          discountTiyn: 0,
        ),
        isNotNull,
      );
      expect(
        validatePurchaseOrderInput(
          supplierPartnerId: 's1',
          items: const [validItem],
          deliveryCostTiyn: 0,
          vatTiyn: 0,
          discountTiyn: -1,
        ),
        isNotNull,
      );
    });

    test('accepts a fully valid order', () {
      expect(
        validatePurchaseOrderInput(
          supplierPartnerId: 's1',
          items: const [validItem],
          deliveryCostTiyn: 500000,
          vatTiyn: 300000,
          discountTiyn: 200000,
        ),
        isNull,
      );
    });
  });
}
