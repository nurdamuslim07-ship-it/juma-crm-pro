import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:juma_ui_crm/core/widgets/swipe_navigation.dart';

void main() {
  testWidgets(
    'swipe and handle reveal navigation without allowing hidden taps',
    (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: SwipeNavigation(
              openLabel: 'Open',
              closeLabel: 'Close',
              child: SizedBox(
                height: 80,
                child: TextButton(
                  onPressed: () => taps++,
                  child: const Text('Action'),
                ),
              ),
            ),
          ),
        ),
      );
      expect(find.text('Action').hitTestable(), findsNothing);
      await tester.drag(find.byType(InkWell).first, const Offset(0, -65));
      await tester.pumpAndSettle();
      expect(find.text('Action').hitTestable(), findsOneWidget);
      await tester.tap(find.text('Action'));
      expect(taps, 1);
      await tester.drag(find.text('Action'), const Offset(0, 65));
      await tester.pumpAndSettle();
      expect(find.text('Action').hitTestable(), findsNothing);
      expect(taps, 1);
      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();
      expect(find.text('Action').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
