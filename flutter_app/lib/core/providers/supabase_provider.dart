import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../error/exceptions.dart';

/// Single Supabase client instance, exposed via Riverpod so every
/// feature's datasource layer gets it through DI (`ref.watch`) instead
/// of a global singleton import — this is what replaces
/// `src/lib/firebase.ts`'s ad hoc helper functions (see
/// UI_ARCHITECTURE.md's target `services/` layer).
///
/// Defense-in-depth guard: `app.dart` never builds anything that
/// reads this provider unless `Supabase.initialize()` already
/// succeeded, but if that invariant is ever broken by future code,
/// this throws a typed, catchable [BackendNotConfiguredException]
/// instead of letting the raw Supabase SDK assertion ("You must
/// initialize the supabase instance...") surface as an uncaught error.
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  try {
    return Supabase.instance.client;
  } catch (_) {
    // Whatever the SDK throws when uninitialized (it's an unchecked
    // assertion, not a documented exception type) — normalize it to
    // our own typed exception rather than letting an unrecognized
    // error type surface raw.
    throw const BackendNotConfiguredException();
  }
});

/// Emits the current auth session, including sign-in/sign-out events —
/// features (router redirect guard, profile menu, etc.) watch this
/// instead of polling `client.auth.currentSession`.
final authStateChangesProvider = StreamProvider<AuthState>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client.auth.onAuthStateChange;
});
