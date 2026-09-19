/// The owner-confirmed 5-stage order workflow (see ORDER_WORKFLOW.md —
/// resolves QUESTIONS_FOR_OWNER.md #8's "exact production stages"
/// question). Mirrors the Postgres `order_status` enum in
/// supabase/migrations/20260713000001_extensions_and_enums.sql
/// exactly — [dbValue]/[fromDbValue] are the only place that mapping
/// is spelled out, so the two never drift silently.
enum OrderStatus {
  measurement,
  accepted,
  inProgress,
  ready,
  installed;

  static OrderStatus fromDbValue(String value) {
    return OrderStatus.values.firstWhere(
      (s) => s.dbValue == value,
      orElse: () => throw ArgumentError('Unknown order_status: $value'),
    );
  }

  String get dbValue {
    switch (this) {
      case OrderStatus.measurement:
        return 'measurement';
      case OrderStatus.accepted:
        return 'accepted';
      case OrderStatus.inProgress:
        return 'in_progress';
      case OrderStatus.ready:
        return 'ready';
      case OrderStatus.installed:
        return 'installed';
    }
  }
}
