import 'package:flutter/foundation.dart';

/// The supplier side of `partners.balance_tiyn` — routed through the
/// Partners module's own `get_partners(p_id: ...)` RPC (already
/// committed; see 20260713000018_partners_module.sql) rather than a
/// new Purchases RPC, since that column IS the authoritative ledger
/// `receive_purchase_order()`/`record_supplier_payment()`/
/// `reverse_supplier_payment()` already write to. Same sign
/// convention as that column's own doc comment: positive = біздің
/// серіктеске қарызымыз бар (our debt to them); negative = біз аванс
/// төледік (we've prepaid them an advance).
///
/// [hasFinancialAccess] mirrors the Partner entity's own
/// `hasFinancialAccess` flag — [balanceTiyn] is legitimately null both
/// when the caller lacks `partners.read_financial` (redacted) and when
/// the balance is exactly zero, so nullability alone can't tell those
/// apart.
@immutable
class SupplierBalance {
  const SupplierBalance({
    required this.partnerId,
    required this.partnerName,
    this.balanceTiyn,
    required this.hasFinancialAccess,
  });

  final String partnerId;
  final String partnerName;
  final int? balanceTiyn;
  final bool hasFinancialAccess;

  bool get isDebt => (balanceTiyn ?? 0) > 0;
  bool get isAdvance => (balanceTiyn ?? 0) < 0;

  /// Zero when there's no outstanding debt (including when in advance).
  int get outstandingDebtTiyn => isDebt ? balanceTiyn! : 0;

  /// Zero when there's no advance (including when in debt).
  int get advanceTiyn => isAdvance ? -balanceTiyn! : 0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SupplierBalance &&
          runtimeType == other.runtimeType &&
          partnerId == other.partnerId;

  @override
  int get hashCode => partnerId.hashCode;
}
