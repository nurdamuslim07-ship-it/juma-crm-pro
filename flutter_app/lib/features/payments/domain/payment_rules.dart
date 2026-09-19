/// Pure overpayment-prevention logic (requirement #12) — mirrors the
/// real server-side guard in `record_payment()`
/// (supabase/migrations/20260713000016_payments_module.sql) exactly,
/// so the form can reject an over-large amount immediately instead of
/// waiting on a round-trip. The server check is what actually matters
/// (this one is UX only, same caveat as every other client-side check
/// in this app), but keeping the two in sync is worth a comment: if
/// this formula and the SQL one ever diverge, the UI would show a
/// misleading "OK" that the server then rejects.
bool wouldOverpay({
  required int orderTotalTiyn,
  required int alreadyPaidTiyn,
  required int newAmountTiyn,
}) {
  return alreadyPaidTiyn + newAmountTiyn > orderTotalTiyn;
}

/// The largest payment that would NOT overpay the order — used to
/// pre-fill/cap the amount field with a sensible default.
int maxPayableTiyn({
  required int orderTotalTiyn,
  required int alreadyPaidTiyn,
}) {
  final remaining = orderTotalTiyn - alreadyPaidTiyn;
  return remaining < 0 ? 0 : remaining;
}
