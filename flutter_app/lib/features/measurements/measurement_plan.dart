import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'measurement_strings.dart';

class RoomPlan {
  RoomPlan(this.points);
  final List<Offset> points;
  factory RoomPlan.fromJson(List<dynamic>? json) => RoomPlan(
    (json ?? [])
        .map(
          (e) => Offset((e['x'] as num).toDouble(), (e['y'] as num).toDouble()),
        )
        .toList(),
  );
  List<Map<String, double>> toJson() =>
      points.map((p) => {'x': p.dx, 'y': p.dy}).toList();
  double get perimeter => points.length < 3
      ? 0
      : List.generate(
          points.length,
          (i) => (points[i] - points[(i + 1) % points.length]).distance,
        ).fold(0.0, (a, b) => a + b);
  double get area {
    if (points.length < 3) return 0;
    var sum = 0.0;
    for (var i = 0; i < points.length; i++) {
      final a = points[i], b = points[(i + 1) % points.length];
      sum += a.dx * b.dy - b.dx * a.dy;
    }
    return sum.abs() / 2;
  }

  bool get valid {
    if (points.isEmpty) return true;
    if (points.length < 3 || area < .01) return false;
    double cross(Offset a, Offset b, Offset c) =>
        (b.dx - a.dx) * (c.dy - a.dy) - (b.dy - a.dy) * (c.dx - a.dx);
    for (var i = 0; i < points.length; i++) {
      final a = points[i], b = points[(i + 1) % points.length];
      if ((a - b).distance < .1) return false;
      for (var j = i + 1; j < points.length; j++) {
        if (j == i + 1 || (i == 0 && j == points.length - 1)) continue;
        final c = points[j], d = points[(j + 1) % points.length];
        if (cross(a, b, c) * cross(a, b, d) <= 0 &&
            cross(c, d, a) * cross(c, d, b) <= 0 &&
            math.max(math.min(a.dx, b.dx), math.min(c.dx, d.dx)) <=
                math.min(math.max(a.dx, b.dx), math.max(c.dx, d.dx)) &&
            math.max(math.min(a.dy, b.dy), math.min(c.dy, d.dy)) <=
                math.min(math.max(a.dy, b.dy), math.max(c.dy, d.dy))) {
          return false;
        }
      }
    }
    return true;
  }
}

class MeasurementPlanEditor extends ConsumerWidget {
  const MeasurementPlanEditor({
    super.key,
    required this.plan,
    required this.onChanged,
  });
  final RoomPlan plan;
  final ValueChanged<RoomPlan> onChanged;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(measurementStringsProvider);
    Future<void> rectangle() async {
      final width = TextEditingController(text: '4');
      final depth = TextEditingController(text: '3');
      String? error;
      final value = await showDialog<RoomPlan>(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: Text(s.rectangle),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: width,
                  decoration: InputDecoration(labelText: s.roomWidth),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                TextField(
                  controller: depth,
                  decoration: InputDecoration(labelText: s.roomDepth),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                if (error != null)
                  Text(
                    error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  final w = double.tryParse(width.text.replaceAll(',', '.')),
                      d = double.tryParse(depth.text.replaceAll(',', '.'));
                  if (w == null ||
                      d == null ||
                      !w.isFinite ||
                      !d.isFinite ||
                      w <= 0 ||
                      d <= 0 ||
                      w > 50 ||
                      d > 50) {
                    setDialogState(() => error = s.roomRange);
                    return;
                  }
                  Navigator.pop(
                    context,
                    RoomPlan([
                      Offset.zero,
                      Offset(w, 0),
                      Offset(w, d),
                      Offset(0, d),
                    ]),
                  );
                },
                child: Text(s.save),
              ),
            ],
          ),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 250));
      width.dispose();
      depth.dispose();
      if (value != null) onChanged(value);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(s.roomPlan, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(s.planHint),
        const SizedBox(height: 12),
        AspectRatio(
          aspectRatio: 1.2,
          child: LayoutBuilder(
            builder: (context, c) {
              final extent = math.max(
                8.0,
                plan.points.fold<double>(
                      0,
                      (m, p) => math.max(m, math.max(p.dx, p.dy)),
                    ) +
                    1,
              );
              final scale = (math.min(c.maxWidth, c.maxHeight) - 40) / extent;
              return GestureDetector(
                onTapUp: (d) {
                  if (plan.points.length >= 24) return;
                  final p = (d.localPosition - const Offset(20, 20)) / scale;
                  if (p.dx < 0 || p.dy < 0 || p.dx > 50 || p.dy > 50) return;
                  onChanged(
                    RoomPlan([
                      ...plan.points,
                      Offset(
                        (p.dx * 10).round() / 10,
                        (p.dy * 10).round() / 10,
                      ),
                    ]),
                  );
                },
                child: CustomPaint(
                  painter: RoomPlanPainter(
                    plan,
                    scale: scale,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              );
            },
          ),
        ),
        if (!plan.valid)
          Text(
            s.invalidPlan,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        if (plan.points.length >= 3 && plan.valid)
          Text(
            '${s.area}: ${plan.area.toStringAsFixed(2)} м²  ·  ${s.perimeter}: ${plan.perimeter.toStringAsFixed(2)} м',
          ),
        Wrap(
          spacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: rectangle,
              icon: const Icon(Icons.crop_square),
              label: Text(s.rectangle),
            ),
            if (plan.points.isNotEmpty)
              TextButton.icon(
                onPressed: () => onChanged(
                  RoomPlan(plan.points.sublist(0, plan.points.length - 1)),
                ),
                icon: const Icon(Icons.undo),
                label: Text(s.undoPoint),
              ),
          ],
        ),
      ],
    );
  }
}

class RoomPlanPainter extends CustomPainter {
  RoomPlanPainter(this.plan, {required this.scale, this.color = Colors.teal});
  final RoomPlan plan;
  final double scale;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = Colors.grey.withValues(alpha: .15)
      ..strokeWidth = 1;
    for (double x = 20; x < size.width; x += scale) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (double y = 20; y < size.height; y += scale) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    final p = plan.points.map((p) => p * scale + const Offset(20, 20)).toList();
    if (p.isEmpty) return;
    final path = Path()..moveTo(p[0].dx, p[0].dy);
    for (final v in p.skip(1)) {
      path.lineTo(v.dx, v.dy);
    }
    if (p.length >= 3) path.close();
    canvas.drawPath(path, Paint()..color = color.withValues(alpha: .1));
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    for (var i = 0; i < p.length; i++) {
      canvas.drawCircle(p[i], 4, Paint()..color = color);
      if (p.length < 2) continue;
      if (i == p.length - 1 && p.length < 3) continue;
      final j = (i + 1) % p.length;
      final label =
          '${(plan.points[i] - plan.points[j]).distance.toStringAsFixed(2)} м';
      final t = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 11,
            backgroundColor: Colors.white,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final center = (p[i] + p[j]) / 2;
      t.paint(
        canvas,
        Offset(
          (center.dx - t.width / 2).clamp(0, math.max(0, size.width - t.width)),
          (center.dy - 15).clamp(0, math.max(0, size.height - t.height)),
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant RoomPlanPainter old) => true;
}
