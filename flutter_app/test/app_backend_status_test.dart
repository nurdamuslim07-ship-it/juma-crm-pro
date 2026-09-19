// Regression test for: "You must initialize the supabase instance
// before calling Supabase.instance".
//
// Root cause was that JumaUiApp always called ref.watch(routerProvider)
// unconditionally, and routerProvider (via supabaseClientProvider and
// GoRouter's own redirect callback) read Supabase.instance.client
// even when main() had skipped Supabase.initialize() because .env
// still had .env.example's placeholder values. Supabase.initialize()
// is deliberately never called anywhere in this test file — if the
// bug regresses, pumping JumaUiApp below throws instead of rendering.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:juma_ui_crm/app.dart';
import 'package:juma_ui_crm/core/config/backend_status.dart';
import 'package:juma_ui_crm/core/providers/backend_status_provider.dart';

void main() {
  testWidgets('renders the Kazakh configuration screen — not a crash — when '
      '.env has no real Supabase credentials', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          backendStatusProvider.overrideWithValue(BackendStatus.notConfigured),
        ],
        child: const JumaUiApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Supabase бапталмаған'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'renders a distinct message when Supabase.initialize() itself failed',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            backendStatusProvider.overrideWithValue(BackendStatus.initFailed),
          ],
          child: const JumaUiApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Supabase-ге қосылу мүмкін болмады'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'demo mode preview opens without ever touching Supabase.instance',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            backendStatusProvider.overrideWithValue(
              BackendStatus.notConfigured,
            ),
          ],
          child: const JumaUiApp(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Демо режимде көру'));
      await tester.pumpAndSettle();

      expect(find.text('Демо режим — JUMA UI'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
