import '../../../payments/domain/value_objects/payment_method.dart';

/// Deliberately a `typedef`, not a new enum — `supplier_payments.method_id`
/// references the exact same `payment_methods` table as `payments`, and
/// [SupplierPayment] already reuses [PaymentMethod] directly (see that
/// entity's doc comment). This alias exists only so the domain layer
/// has a symbol literally named `SupplierPaymentMethod`, without
/// duplicating the 5-way (cash/kaspi/bank_transfer/card/other) mapping
/// a second time.
typedef SupplierPaymentMethod = PaymentMethod;
