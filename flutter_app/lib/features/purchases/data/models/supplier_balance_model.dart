import '../../domain/entities/supplier_balance.dart';

/// Parses a row from the Partners module's own `get_partners(p_id: ...)`
/// RPC — see supabase/migrations/20260713000018_partners_module.sql —
/// not a new Purchases RPC.
class SupplierBalanceModel extends SupplierBalance {
  const SupplierBalanceModel({
    required super.partnerId,
    required super.partnerName,
    super.balanceTiyn,
    required super.hasFinancialAccess,
  });

  factory SupplierBalanceModel.fromRow(Map<String, dynamic> row) {
    return SupplierBalanceModel(
      partnerId: row['id'] as String,
      partnerName: (row['display_name'] as String?) ?? '',
      balanceTiyn: (row['balance_tiyn'] as num?)?.toInt(),
      hasFinancialAccess: (row['has_financial_access'] as bool?) ?? false,
    );
  }
}
