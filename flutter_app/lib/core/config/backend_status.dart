/// Result of the one-time Supabase bootstrap attempt in `main()`.
///
/// This is deliberately a runtime fact injected via a Riverpod
/// override (see `backendStatusProvider`), not something recomputed
/// from `Env.isConfigured` inside the widget tree — `Env.isConfigured`
/// only checks whether `.env` *looks* filled in, it can't tell us
/// whether `Supabase.initialize()` actually succeeded. Only `main()`
/// knows that, since it's the only place that calls `initialize()`.
enum BackendStatus {
  /// `.env` has no real SUPABASE_URL/SUPABASE_ANON_KEY (still the
  /// `your-project.supabase.co` / `your-anon-key` placeholders from
  /// `.env.example`, or missing entirely).
  notConfigured,

  /// Values looked real but `Supabase.initialize()` itself threw
  /// (malformed URL, etc.).
  initFailed,

  /// `Supabase.initialize()` completed — `Supabase.instance.client`
  /// is safe to use anywhere below this point in the tree.
  ready,
}
