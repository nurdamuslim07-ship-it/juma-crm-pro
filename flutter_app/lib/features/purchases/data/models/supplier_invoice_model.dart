import '../../domain/entities/supplier_invoice.dart';
import '../../domain/entities/supplier_invoice_status.dart';

class SupplierInvoiceModel extends SupplierInvoice {
  const SupplierInvoiceModel({
    required super.id,
    required super.invoiceNumber,
    super.purchaseOrderId,
    super.purchaseOrderNumber,
    required super.amountTiyn,
    required super.status,
    required super.issuedAt,
    super.dueDate,
    required super.paidAmountTiyn,
  });

  factory SupplierInvoiceModel.fromRow(Map<String, dynamic> row) {
    return SupplierInvoiceModel(
      id: row['id'] as String,
      invoiceNumber: (row['invoice_number'] as String?) ?? '',
      purchaseOrderId: row['purchase_order_id'] as String?,
      purchaseOrderNumber: row['purchase_order_number'] as String?,
      amountTiyn: (row['amount_tiyn'] as num?)?.toInt() ?? 0,
      status: SupplierInvoiceStatusX.fromKey(row['status'] as String),
      issuedAt: DateTime.parse(row['issued_at'] as String),
      dueDate: row['due_date'] == null
          ? null
          : DateTime.parse(row['due_date'] as String),
      paidAmountTiyn: (row['paid_amount_tiyn'] as num?)?.toInt() ?? 0,
    );
  }
}
