import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:juma_ui_crm/core/widgets/app_button.dart';

void main() {
  testWidgets('long button label wraps at narrow widths and large text', (
    tester,
  ) async {
    for (final scale in [1.0, 2.0]) {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(scale)),
            child: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 150,
                  child: AppButton(
                    label: 'Қоңырау шалу',
                    icon: Icons.phone,
                    onPressed: () {},
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Қоңырау шалу').hitTestable(), findsOneWidget);
    }
  });
}
