import 'package:flutter_test/flutter_test.dart';
import 'package:juma_ui_crm/features/quick_estimate/estimate_model.dart';

void main() {
  test('comma and dot coefficients, exact required example', () {
    final e = Estimate();
    for (final l in e.lines) {
      l.manualQuantity = 0;
    }
    e.lines.first
      ..manualQuantity = 1
      ..price = 20000000;
    for (final c in ['1,5', '1.5']) {
      e.coefficient = c;
      expect(e.cost, 20000000);
      expect(e.sale, 30000000);
      expect(e.profit, 10000000);
    }
    e.discount = '10';
    expect(e.sale, 27000000);
    e.discountPercent = false;
    e.discount = '12500,50';
    expect(e.sale, 28749950);
    e.discount = '9999999';
    expect(e.validate(), isNotNull);
  });
  test('dimensions, thickness, shelves, drawers and waste', () {
    final e = Estimate();
    e.sections = [
      CabinetSection(
        width: 1000,
        height: 2000,
        depth: 600,
        shelves: 2,
        doors: 2,
      ),
    ];
    expect(e.quantities()['body'], closeTo(4.7136, 0.000001));
    expect(e.quantities()['front'], 2);
    expect(e.quantities()['hinges'], 6);
    final body = e.lines.first;
    expect(e.quantity(body), closeTo(5.18496, .000001));
    body.unit = 'парақ';
    body.sheetWidth = 1000;
    body.sheetHeight = 2000;
    expect(e.quantity(body), 3);
    body.manualQuantity = 2;
    expect(e.quantity(body), 2);
    e.sections.first.width = 1500;
    expect(e.quantity(body), 2);
    body.manualQuantity = null;
    expect(e.quantity(body), greaterThan(2));
    e.sections.first.drawers = 2;
    expect(e.quantities()['runners'], 2);
    expect(e.quantities()['mechanism'], 0);
  });
  test(
    'kitchen upper and lower are counted separately, corner has no overlap',
    () {
      final e = Estimate()
        ..kitchen = true
        ..corner = true
        ..width = 1800
        ..second = 1200
        ..height = 720;
      e.rebuild();
      expect(e.sections.length, 12);
      expect(e.quantities()['length'], closeTo(3, .000001));
      expect(e.quantities()['top'], closeTo(1.8, .000001));
      expect(e.quantities()['panel'], closeTo(1.8, .000001));
      e.upper = false;
      e.rebuild();
      expect(e.sections.length, 6);
      e.kitchen = false;
      e.sliding = true;
      e.rebuild();
      expect(e.quantities()['hinges'], 0);
      expect(e.quantities()['sliding'], 2);
    },
  );
  test('no fabricated prices, snapshot copy detached and stable', () {
    final e = Estimate();
    expect(e.cost, 0);
    expect(e.unpriced, isNotEmpty);
    e.lines.first.price = 450000;
    final restored = Estimate.fromJson(e.toJson());
    final cost = restored.cost;
    e.lines.first.price = 999999;
    expect(restored.cost, cost);
    expect(
      restored.lines.map((l) => l.id).toSet().length,
      restored.lines.length,
    );
    restored.rebuild();
    expect(
      restored.lines.map((l) => l.id).toSet().length,
      restored.lines.length,
    );
  });
  test('reject invalid numbers and nonpositive geometry', () {
    for (final value in ['-1', 'NaN', 'Infinity', '1e4', '1,2.3', '']) {
      expect(decimal(value), isNull);
    }
    expect(decimal('10,25', digits: 2), 1025);
    expect(decimal('1.001', digits: 2), isNull);
    final e = Estimate();
    e.sections.first.width = -1;
    expect(e.validate(), isNotNull);
  });
}
