import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart';
import 'measurement_gallery.dart';
import 'measurement_photo.dart';
import 'measurement_plan.dart';
import 'measurement_strings.dart';

Future<Uint8List> measurementPhotoPng(
  Uint8List bytes,
  List<Map<String, dynamic>> annotations,
) async {
  final codec = await ui.instantiateImageCodec(bytes, targetWidth: 1400);
  final frame = await codec.getNextFrame();
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  const size = Size(1200, 900);
  canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);
  final image = frame.image;
  final fitted = applyBoxFit(
    BoxFit.contain,
    Size(image.width.toDouble(), image.height.toDouble()),
    size,
  );
  canvas.drawImageRect(
    image,
    Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
    Alignment.center.inscribe(fitted.destination, Offset.zero & size),
    Paint(),
  );
  MeasurementArrowPainter(annotations).paint(canvas, size);
  final picture = recorder.endRecording();
  final output = await picture.toImage(1200, 900);
  final data = await output.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  codec.dispose();
  picture.dispose();
  output.dispose();
  return data!.buffer.asUint8List();
}

Future<Uint8List> measurementPlanPng(RoomPlan plan) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  const size = Size(700, 600);
  canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);
  final extent = math.max(
    8.0,
    plan.points.fold<double>(0, (m, p) => math.max(m, math.max(p.dx, p.dy))) +
        1,
  );
  RoomPlanPainter(plan, scale: 560 / extent).paint(canvas, size);
  final picture = recorder.endRecording();
  final output = await picture.toImage(700, 600);
  final data = await output.toByteData(format: ui.ImageByteFormat.png);
  picture.dispose();
  output.dispose();
  return data!.buffer.asUint8List();
}

Future<Uint8List> buildMeasurementPdf({
  required MeasurementStrings strings,
  required String clientName,
  required Map<String, String> fields,
  required RoomPlan plan,
  required List<MeasurementPhotoDraft> photos,
  required Future<Uint8List> Function(String) download,
  pw.Font? fontOverride,
}) async {
  final s = strings;
  final font =
      fontOverride ??
      pw.Font.ttf(await rootBundle.load('assets/fonts/NotoSans-Regular.ttf'));
  final doc = pw.Document(
    theme: pw.ThemeData.withFont(base: font, bold: font),
  );
  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(36),
      build: (_) => [
        pw.Text('JUMA · ${s.sheet}', style: pw.TextStyle(fontSize: 22)),
        pw.SizedBox(height: 20),
        for (final entry in <String, String>{
          s.client: clientName,
          s.address: fields['address'] ?? '',
          s.product: fields['room_type'] ?? '',
          s.material: fields['material'] ?? '',
          s.width: fields['width'] ?? '',
          s.height: fields['height'] ?? '',
          s.depth: fields['depth'] ?? '',
          s.amount: fields['price'] ?? '',
          s.notes: fields['notes'] ?? '',
        }.entries)
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 10),
            child: pw.Text('${entry.key}: ${entry.value}'),
          ),
      ],
    ),
  );
  if (plan.points.length >= 3) {
    final image = await measurementPlanPng(plan);
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(s.roomPlan, style: pw.TextStyle(fontSize: 20)),
            pw.SizedBox(height: 16),
            pw.Image(pw.MemoryImage(image)),
            pw.SizedBox(height: 16),
            pw.Text(
              '${s.area}: ${plan.area.toStringAsFixed(2)} м² · ${s.perimeter}: ${plan.perimeter.toStringAsFixed(2)} м',
            ),
          ],
        ),
      ),
    );
  }
  for (var i = 0; i < photos.length; i++) {
    final photo = photos[i];
    final source = photo.bytes ?? await download(photo.path!);
    final image = await measurementPhotoPng(source, photo.annotations);
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              '${s.photos} ${i + 1} / ${photos.length}',
              style: pw.TextStyle(fontSize: 20),
            ),
            pw.SizedBox(height: 16),
            pw.Image(pw.MemoryImage(image)),
            pw.SizedBox(height: 16),
            pw.Text(clientName),
          ],
        ),
      ),
    );
  }
  return doc.save();
}
