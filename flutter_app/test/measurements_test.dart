import 'package:juma_ui_crm/features/measurements/measurement_photo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:juma_ui_crm/core/theme/app_theme.dart';
import 'package:juma_ui_crm/features/measurements/measurement_repository.dart';
import 'package:juma_ui_crm/features/measurements/measurement_form.dart';
import 'package:juma_ui_crm/features/measurements/measurements_screen.dart';

void main() {
  testWidgets('photo drag produces normalized annotation coordinates', (
    tester,
  ) async {
    Offset? start, end;
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox(
            width: 400,
            child: MeasurementPhoto(
              arrows: const [],
              onArrow: (a, b) {
                start = a;
                end = b;
              },
            ),
          ),
        ),
      ),
    );
    final rect = tester.getRect(find.byType(MeasurementPhoto));
    await tester.dragFrom(
      rect.topLeft + const Offset(60, 60),
      const Offset(180, 100),
    );
    await tester.pumpAndSettle();
    expect(start, isNotNull);
    expect(end, isNotNull);
    expect(end!.dx, inInclusiveRange(0, 1));
    expect(end!.dy, inInclusiveRange(0, 1));
    expect((end! - start!).distance, greaterThan(.03));
  });
  testWidgets('two taps add a photo measurement', (tester) async {
    Offset? start, end;
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox(
            width: 400,
            child: MeasurementPhoto(
              arrows: const [],
              onArrow: (a, b) {
                start = a;
                end = b;
              },
            ),
          ),
        ),
      ),
    );
    final rect = tester.getRect(find.byType(MeasurementPhoto));
    await tester.tapAt(rect.topLeft + const Offset(50, 50));
    await tester.pump();
    await tester.tapAt(rect.topLeft + const Offset(200, 150));
    await tester.pump();
    expect(start, const Offset(.125, 1 / 6));
    expect(end, const Offset(.5, .5));
  });
  test('money uses integer tiyn and rejects invalid input', () {
    expect(measurementPriceTiyn('280000'), 28000000);
    expect(measurementPriceTiyn('12,35'), 1235);
    expect(measurementPriceTiyn('0.01'), 1);
    for (final invalid in ['-1', 'NaN', '1.234', '', '1e6']) {
      expect(measurementPriceTiyn(invalid), isNull);
    }
  });
  for (final size in [
    const Size(320, 700),
    const Size(402, 874),
    const Size(1024, 768),
  ]) {
    testWidgets('measurement form validates and fits $size', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const MeasurementForm(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Сақтау'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Сақтау'));
      await tester.pumpAndSettle();
      expect(find.text('Нөлден үлкен сан енгізіңіз'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
    testWidgets('measurement list searches persisted rows at $size', (
      tester,
    ) async {
      await initializeDateFormatting('kk');
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            measurementsProvider.overrideWith(
              (ref) async => [
                {
                  'id': 'test',
                  'client': {'name': 'Саят'},
                  'address': 'Алматы',
                  'created_at': '2026-09-19T10:00:00Z',
                  'width': 2400,
                  'height': 2600,
                  'depth': 600,
                  'estimated_amount_tiyn': 35000000,
                },
              ],
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const MeasurementsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Саят'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Астана');
      await tester.pumpAndSettle();
      expect(find.text('Ештеңе табылмады'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
