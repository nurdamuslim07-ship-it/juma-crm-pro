import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:juma_ui_crm/features/measurements/measurement_gallery.dart';
import 'package:juma_ui_crm/features/measurements/measurement_plan.dart';
import 'package:juma_ui_crm/features/measurements/measurement_pdf.dart';
import 'package:juma_ui_crm/features/measurements/measurement_strings.dart';
import 'package:pdf/src/pdf/font/ttf_parser.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('gallery migrates legacy photos but respects an empty gallery', () {
    expect(
      MeasurementPhotoDraft.fromRow({'photo_path': 'old.jpg'}).single.path,
      'old.jpg',
    );
    expect(
      MeasurementPhotoDraft.fromRow({
        'photo_path': 'old.jpg',
        'photo_gallery': [],
      }),
      isEmpty,
    );
    final photos = MeasurementPhotoDraft.fromRow({
      'photo_gallery': [
        {
          'path': 'a.jpg',
          'annotations': [
            {'label': '1000'},
          ],
        },
        {'path': 'b.jpg', 'annotations': []},
      ],
    });
    photos[0].annotations.add({'label': '2000'});
    expect(photos[1].annotations, isEmpty);
    expect(photos.map((p) => p.toJson()).toList().length, 2);
  });
  test('plan area/perimeter and invalid crossing walls', () {
    final plan = RoomPlan([
      Offset.zero,
      const Offset(4, 0),
      const Offset(4, 3),
      const Offset(0, 3),
    ]);
    expect(plan.area, 12);
    expect(plan.perimeter, 14);
    expect(plan.valid, isTrue);
    expect(RoomPlan.fromJson(plan.toJson()).area, 12);
    expect(
      RoomPlan([
        Offset.zero,
        const Offset(4, 3),
        const Offset(4, 0),
        const Offset(0, 3),
      ]).valid,
      isFalse,
    );
    expect(RoomPlan([Offset.zero, const Offset(1, 0)]).valid, isFalse);
  });
  test('PDF font includes Kazakh letters and tenge', () async {
    final bytes = await rootBundle.load('assets/fonts/NotoSans-Regular.ttf');
    final parser = TtfParser(bytes);
    for (final char in 'ӘҒҚҢӨҰҮҺІәғқңөұүһі₸'.runes) {
      expect(
        parser.charToGlyphIndexMap[char],
        isNotNull,
        reason: String.fromCharCode(char),
      );
    }
  });
  testWidgets('gallery switches photos and exposes delete/add controls', (
    tester,
  ) async {
    final png = base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+a9V8AAAAASUVORK5CYII=',
    );
    final photos = [
      MeasurementPhotoDraft(bytes: png),
      MeasurementPhotoDraft(bytes: png),
    ];
    var selected = 0;
    var deleted = false;
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (_, setState) => SingleChildScrollView(
                child: MeasurementGallery(
                  photos: photos,
                  selected: selected,
                  onSelect: (i) => setState(() => selected = i),
                  onAdd: () {},
                  onDelete: () => setState(() {
                    photos.removeAt(selected);
                    selected = 0;
                    deleted = true;
                  }),
                  onArrow: (_, _) {},
                  onUndo: () {},
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.bySemanticsLabel('Фотолар 2'));
    await tester.tap(find.bySemanticsLabel('Фотолар 2'));
    await tester.pumpAndSettle();
    expect(selected, 1);
    await tester.ensureVisible(find.text('Фотоны өшіру'));
    await tester.tap(find.text('Фотоны өшіру'));
    await tester.pumpAndSettle();
    expect(deleted, isTrue);
    expect(photos.length, 1);
    expect(find.text('Фотолар қосу'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  test('PDF includes summary, plan, and annotated photo', () async {
    final photo = await rootBundle.load('assets/images/living-room.jpg');
    final bytes = await buildMeasurementPdf(
      strings: const MeasurementStrings(false),
      clientName: 'Тест клиенті',
      fields: {
        'address': 'Өлшеу мекенжайы',
        'width': '2000',
        'height': '2400',
        'depth': '600',
        'price': '280000',
      },
      plan: RoomPlan([
        Offset.zero,
        const Offset(4, 0),
        const Offset(4, 3),
        const Offset(0, 3),
      ]),
      photos: [
        MeasurementPhotoDraft(
          bytes: photo.buffer.asUint8List(),
          annotations: [
            {'x1': .1, 'y1': .2, 'x2': .8, 'y2': .2, 'label': '2000 мм'},
          ],
        ),
      ],
      download: (_) async => Uint8List(0),
    );
    expect(ascii.decode(bytes.take(4).toList()), '%PDF');
    expect(bytes.length, greaterThan(10000));
    await File('/tmp/juma-measurement-preview.pdf').writeAsBytes(bytes);
  });
}
