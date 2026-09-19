/// The 5 payment types requirement #5 lists, mirroring the seeded
/// `payment_methods` rows in supabase/seed/seed.sql exactly —
/// [dbKey]/[fromDbKey] are the only place that mapping is spelled out.
enum PaymentMethod {
  cash,
  kaspi,
  bankTransfer,
  card,
  other;

  static PaymentMethod fromDbKey(String key) {
    return PaymentMethod.values.firstWhere(
      (m) => m.dbKey == key,
      orElse: () => throw ArgumentError('Unknown payment method key: $key'),
    );
  }

  String get dbKey {
    switch (this) {
      case PaymentMethod.cash:
        return 'cash';
      case PaymentMethod.kaspi:
        return 'kaspi';
      case PaymentMethod.bankTransfer:
        return 'bank_transfer';
      case PaymentMethod.card:
        return 'card';
      case PaymentMethod.other:
        return 'other';
    }
  }
}
