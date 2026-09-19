import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:juma_ui_crm/core/error/exceptions.dart';
import 'package:juma_ui_crm/features/orders/presentation/providers/order_providers.dart';

void main() {
  group('invalidation contract every realtime provider relies on', () {
    // Actually opening a Postgres Changes subscription needs a live
    // Supabase connection (not available in this environment — see
    // supabase/README.md's own "not executed against a live database"
    // caveat, which applies here too). What IS testable without one:
    // the mechanism the realtime callback calls into — `ref.invalidate`
    // forcing a provider's next read to refetch — which is the actual
    // thing that makes "Realtime instead of polling" work.
    test(
      'invalidating a FutureProvider forces its next read to recompute',
      () async {
        var callCount = 0;
        final counterProvider = FutureProvider.autoDispose<int>((ref) async {
          callCount++;
          return callCount;
        });

        final container = ProviderContainer();
        addTearDown(container.dispose);

        final first = await container.read(counterProvider.future);
        expect(first, 1);

        // This is exactly what every `tableRealtimeProvider(...)` callback
        // does on a postgres_changes event — see e.g.
        // `ordersRealtimeProvider` in order_providers.dart.
        container.invalidate(counterProvider);

        final second = await container.read(counterProvider.future);
        expect(second, 2);
      },
    );
  });

  group('tableRealtimeProvider construction', () {
    test('building a realtime provider without a live Supabase connection '
        'throws the typed BackendNotConfiguredException, not a raw crash', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // ordersRealtimeProvider is built from tableRealtimeProvider(),
      // which watches supabaseClientProvider first — in a test
      // environment (Supabase.initialize() never called), that
      // provider's own defense-in-depth guard throws this typed
      // exception rather than the SDK's raw uninitialized-instance
      // assertion. Confirms the same safety net Stage 1's
      // supabase_client_provider.dart already relies on elsewhere
      // extends correctly to every Stage 4 realtime provider too.
      expect(
        () => container.read(ordersRealtimeProvider),
        throwsA(isA<BackendNotConfiguredException>()),
      );
    });
  });
}
