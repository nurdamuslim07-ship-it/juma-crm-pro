import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:juma_ui_crm/core/widgets/press_motion.dart';
import 'package:juma_ui_crm/core/theme/app_theme.dart';

void main() {
  testWidgets('press releases on scrolling and does not activate the button', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            children: [
              MotionInkWell(
                onTap: () => taps++,
                child: const SizedBox(height: 80, child: Text('Tap')),
              ),
              const SizedBox(height: 1600),
            ],
          ),
        ),
      ),
    );
    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Tap')),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, .97);
    await gesture.moveBy(const Offset(0, -70));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(taps, 0);
    expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 1);
  });
  testWidgets('reduced motion and disabled buttons remain still', (
    tester,
  ) async {
    for (final disabled in [false, true]) {
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: Scaffold(
              body: FilledButton(
                onPressed: disabled ? null : () => taps++,
                child: const Text('Tap'),
              ),
            ),
          ),
        ),
      );
      final gesture = await tester.startGesture(
        tester.getCenter(find.text('Tap')),
      );
      await tester.pump();
      expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 1);
      await gesture.up();
      await tester.pumpAndSettle();
      expect(taps, disabled ? 0 : 1);
    }
  });
}
