import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/backend_status.dart';

/// Always overridden in `main()` with the real result of the
/// `Supabase.initialize()` attempt (see `backend_status.dart`) before
/// `runApp()` is called — the `UnimplementedError` here is a
/// programmer-error guard, not a real runtime path: if this default
/// is ever hit, it means some widget read this provider outside the
/// `ProviderScope` that `main.dart` configures, which is itself a bug.
final backendStatusProvider = Provider<BackendStatus>((ref) {
  throw UnimplementedError(
    'backendStatusProvider must be overridden in main() before runApp()',
  );
});

/// Toggled by the "Демо режимде көру" button on
/// [ConfigurationErrorScreen] — pure UI state, never read by anything
/// that touches Supabase (see DemoPreviewScreen).
final demoModeProvider = StateProvider<bool>((ref) => false);
