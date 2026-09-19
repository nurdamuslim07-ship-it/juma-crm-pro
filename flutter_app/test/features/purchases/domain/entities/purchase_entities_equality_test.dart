import 'package:flutter_test/flutter_test.dart';
import 'package:juma_ui_crm/features/purchases/domain/entities/purchase_order_item.dart';
import 'package:juma_ui_crm/features/purchases/domain/entities/purchase_order_status.dart';
import 'package:juma_ui_crm/features/purchases/domain/entities/purchase_order_summary.dart';
import 'package:juma_ui_crm/features/purchases/domain/entities/supplier_invoice.dart';
import 'package:juma_ui_crm/features/purchases/domain/entities/supplier_invoice_status.dart';
import 'package:juma_ui_crm/features/purchases/domain/entities/supplier_payment.dart';

void main() {
  test('PurchaseOrderStatusX.fromKey round-trips every enum value', () {
    for (final status in PurchaseOrderStatus.values) {
      expect(PurchaseOrderStatusX.fromKey(status.key), status);
    }
  });

  test(
    'PurchaseOrderStatusX.fromKey falls back to draft for an unknown key',
    () {
      expect(
        PurchaseOrderStatusX.fromKey('not-a-real-status'),
        PurchaseOrderStatus.draft,
      );
    },
  );

  test('SupplierInvoiceStatusX.fromKey round-trips every enum value', () {
    for (final status in SupplierInvoiceStatus.values) {
      expect(SupplierInvoiceStatusX.fromKey(status.name), status);
    }
  });

  test(
    'SupplierInvoiceStatusX.fromKey falls back to unpaid for an unknown key',
    () {
      expect(
        SupplierInvoiceStatusX.fromKey('bogus'),
        SupplierInvoiceStatus.unpaid,
      );
    },
  );

  test('PurchaseOrderSummary equality is based on id only', () {
    final a = PurchaseOrderSummary(
      id: 'po1',
      orderNumber: 'PO-0001',
      supplierPartnerId: 's1',
      supplierName: 'Жеткізуші А',
      status: PurchaseOrderStatus.draft,
      itemsCount: 1,
      totalAmountTiyn: 1000,
      createdAt: DateTime(2026, 7, 13),
    );
    final b = PurchaseOrderSummary(
      id: 'po1',
      orderNumber: 'PO-9999',
      supplierPartnerId: 's2',
      supplierName: 'Жеткізуші Б',
      status: PurchaseOrderStatus.received,
      itemsCount: 9,
      totalAmountTiyn: 999999,
      createdAt: DateTime(2026, 7, 14),
    );
    expect(a, equals(b));
    expect(a.hashCode, b.hashCode);
  });

  test(
    'PurchaseOrderItem equality is based on materialId + locationId, not quantity',
    () {
      const a = PurchaseOrderItem(
        materialId: 'm1',
        quantity: 5,
        unit: 'парақ',
        unitPriceTiyn: 100,
        locationId: 'l1',
      );
      const b = PurchaseOrderItem(
        materialId: 'm1',
        quantity: 20,
        unit: 'парақ',
        unitPriceTiyn: 999,
        locationId: 'l1',
      );
      expect(a, equals(b));

      const differentLocation = PurchaseOrderItem(
        materialId: 'm1',
        quantity: 5,
        unit: 'парақ',
        unitPriceTiyn: 100,
        locationId: 'l2',
      );
      expect(a, isNot(equals(differentLocation)));
    },
  );

  test(
    'PurchaseOrderItem.copyWith replaces quantity/unitPrice/location only',
    () {
      const item = PurchaseOrderItem(
        materialId: 'm1',
        quantity: 5,
        unit: 'парақ',
        unitPriceTiyn: 100,
        locationId: 'l1',
      );
      final updated = item.copyWith(quantity: 8, unitPriceTiyn: 200);
      expect(updated.quantity, 8);
      expect(updated.unitPriceTiyn, 200);
      expect(updated.materialId, 'm1');
    },
  );

  test('SupplierInvoice equality is based on id only', () {
    final a = SupplierInvoice(
      id: 'inv1',
      invoiceNumber: 'PO-0001',
      amountTiyn: 1000,
      status: SupplierInvoiceStatus.unpaid,
      issuedAt: DateTime(2026, 7, 13),
      paidAmountTiyn: 0,
    );
    final b = SupplierInvoice(
      id: 'inv1',
      invoiceNumber: 'PO-9999',
      amountTiyn: 9999,
      status: SupplierInvoiceStatus.paid,
      issuedAt: DateTime(2026, 7, 14),
      paidAmountTiyn: 9999,
    );
    expect(a, equals(b));
  });

  test('SupplierPayment equality is based on id only', () {
    final a = SupplierPayment(
      id: 'p1',
      amountTiyn: 1000,
      paidAt: DateTime(2026, 7, 13),
      isReversed: false,
      createdAt: DateTime(2026, 7, 13),
    );
    final b = SupplierPayment(
      id: 'p1',
      amountTiyn: 9999,
      paidAt: DateTime(2026, 7, 14),
      isReversed: true,
      createdAt: DateTime(2026, 7, 14),
    );
    expect(a, equals(b));
  });
}
