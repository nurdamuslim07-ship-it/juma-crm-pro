// Smoke test for the core design-system scaffold. Module-specific tests
// (auth, payments, order state machine — in that priority order, see
// TESTING_PLAN.md) are added alongside each module's implementation
// rather than upfront.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:juma_ui_crm/core/theme/app_theme.dart';
import 'package:juma_ui_crm/core/theme/glass/liquid_glass.dart';

void main() {
  testWidgets('LiquidGlass renders its child', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(body: LiquidGlass(child: Text('JUMA UI'))),
      ),
    );

    expect(find.text('JUMA UI'), findsOneWidget);
  });

  test('Light and dark themes build without throwing', () {
    expect(AppTheme.light, returnsNormally);
    expect(AppTheme.dark, returnsNormally);
  });
}
