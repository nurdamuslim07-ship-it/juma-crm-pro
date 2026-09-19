import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';

/// Normalized coordinates keep annotations aligned at phone/tablet sizes.
class MeasurementPhoto extends StatefulWidget {
  const MeasurementPhoto({
    super.key,
    this.bytes,
    this.url,
    required this.arrows,
    this.onArrow,
  });
  final Uint8List? bytes;
  final String? url;
  final List<Map<String, dynamic>> arrows;
  final void Function(Offset start, Offset end)? onArrow;
  @override
  State<MeasurementPhoto> createState() => _MeasurementPhotoState();
}

class _MeasurementPhotoState extends State<MeasurementPhoto> {
  Offset? start, end;
  bool dragging = false;
  void finish() {
    final a = start, b = end;
    dragging = false;
    setState(() {
      start = null;
      end = null;
    });
    if (a != null && b != null && (a - b).distance > .03) {
      widget.onArrow?.call(a, b);
    }
  }

  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: 4 / 3,
    child: LayoutBuilder(
      builder: (context, c) {
        Offset normalize(Offset p) => Offset(
          (p.dx / c.maxWidth).clamp(0, 1),
          (p.dy / c.maxHeight).clamp(0, 1),
        );
        return GestureDetector(
          onTapUp: widget.onArrow == null
              ? null
              : (d) {
                  if (start == null) {
                    setState(() => start = normalize(d.localPosition));
                  } else {
                    end = normalize(d.localPosition);
                    finish();
                  }
                },
          onPanStart: widget.onArrow == null
              ? null
              : (d) => setState(() {
                  dragging = true;
                  start = normalize(d.localPosition);
                }),
          onPanUpdate: widget.onArrow == null
              ? null
              : (d) => setState(() => end = normalize(d.localPosition)),
          onPanEnd: widget.onArrow == null ? null : (_) => finish(),
          onPanCancel: () {
            if (dragging) {
              setState(() {
                dragging = false;
                start = null;
                end = null;
              });
            }
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Stack(
              fit: StackFit.expand,
              children: [
                ColoredBox(
                  color: Colors.black12,
                  child: widget.bytes != null
                      ? Image.memory(widget.bytes!, fit: BoxFit.contain)
                      : widget.url != null
                      ? Image.network(
                          widget.url!,
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) =>
                              const Icon(Icons.broken_image_outlined),
                        )
                      : const Icon(Icons.add_a_photo_outlined, size: 44),
                ),
                CustomPaint(
                  painter: MeasurementArrowPainter([
                    ...widget.arrows,
                    if (start != null && end != null)
                      {
                        'x1': start!.dx,
                        'y1': start!.dy,
                        'x2': end!.dx,
                        'y2': end!.dy,
                        'label': '',
                      },
                  ]),
                ),
                if (start != null)
                  Positioned(
                    left: start!.dx * c.maxWidth - 5,
                    top: start!.dy * c.maxHeight - 5,
                    child: const IgnorePointer(
                      child: Icon(
                        Icons.circle,
                        size: 10,
                        color: Colors.deepOrange,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

class MeasurementArrowPainter extends CustomPainter {
  MeasurementArrowPainter(this.arrows);
  final List<Map<String, dynamic>> arrows;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.deepOrange
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    for (final a in arrows) {
      final start = Offset(
        (a['x1'] as num).toDouble() * size.width,
        (a['y1'] as num).toDouble() * size.height,
      );
      final end = Offset(
        (a['x2'] as num).toDouble() * size.width,
        (a['y2'] as num).toDouble() * size.height,
      );
      if (a['shape'] == 'rectangle') {
        canvas.drawRect(Rect.fromPoints(start, end), paint);
      } else {
        canvas.drawLine(start, end, paint);
        final angle = math.atan2(end.dy - start.dy, end.dx - start.dx);
        for (final sign in [-1, 1]) {
          final delta =
              Offset(math.cos(angle + sign * .5), math.sin(angle + sign * .5)) *
              12;
          canvas.drawLine(end, end - delta, paint);
          canvas.drawLine(start, start + delta, paint);
        }
      }
      final text = TextPainter(
        text: TextSpan(
          text: a['label'] as String? ?? '',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: size.width * .8);
      final center = (start + end) / 2;
      final position = Offset(
        (center.dx - text.width / 2).clamp(
          4,
          math.max(4, size.width - text.width - 4),
        ),
        (center.dy - 24).clamp(4, math.max(4, size.height - text.height - 4)),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          (position & text.size).inflate(4),
          const Radius.circular(5),
        ),
        Paint()..color = Colors.black87,
      );
      text.paint(canvas, position);
    }
  }

  @override
  bool shouldRepaint(covariant MeasurementArrowPainter oldDelegate) => true;
}
