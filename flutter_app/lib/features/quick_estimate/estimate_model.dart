import 'dart:math' as math;

// Decimal input uses a fixed scale; money is always stored in integer tiyn.
int? decimal(String text, {int digits = 6}) {
  final s = text.trim().replaceAll(',', '.');
  if (!RegExp(r'^\d{1,9}(\.\d{1,6})?$').hasMatch(s)) return null;
  final p = s.split('.');
  final fraction = p.length == 1 ? '' : p[1];
  if (fraction.length > digits) return null;
  return int.parse(p[0]) * math.pow(10, digits).toInt() +
      (digits == 0 ? 0 : int.parse(fraction.padRight(digits, '0')));
}

int roundedProduct(int a, int b, int divisor) =>
    (a * b + divisor ~/ 2) ~/ divisor;
double number(String s) => (decimal(s) ?? 0) / 1000000;
String qty(double n) =>
    n.toStringAsFixed(6).replaceFirst(RegExp(r'\.?0+$'), '');
const units = ['м²', 'пог. м', 'дана', 'парақ'];

class CabinetSection {
  CabinetSection({
    this.width = 600,
    this.height = 2400,
    this.depth = 600,
    this.shelves = 3,
    this.doors = 1,
    this.drawers = 0,
    this.level = 'Корпус',
    this.wing = 1,
  });
  double width, height, depth;
  int shelves, doors, drawers, wing;
  String level;
  Map<String, dynamic> toJson() => {
    'w': width,
    'h': height,
    'd': depth,
    's': shelves,
    'doors': doors,
    'drawers': drawers,
    'level': level,
    'wing': wing,
  };
  factory CabinetSection.fromJson(Map<String, dynamic> j) => CabinetSection(
    width: (j['w'] as num).toDouble(),
    height: (j['h'] as num).toDouble(),
    depth: (j['d'] as num).toDouble(),
    shelves: j['s'],
    doors: j['doors'],
    drawers: j['drawers'],
    level: j['level'],
    wing: j['wing'],
  );
}

class CostLine {
  CostLine({
    required this.id,
    required this.name,
    required this.group,
    this.unit = 'дана',
    this.price,
    this.manualQuantity,
    this.material = '',
    this.color = '',
    this.thickness = 18,
    this.sheetWidth = 2800,
    this.sheetHeight = 2070,
    this.waste = 10,
  });
  String id, name, group, unit, material, color;
  int? price;
  double? manualQuantity;
  double thickness, sheetWidth, sheetHeight, waste;
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'group': group,
    'unit': unit,
    'price': price,
    'quantity': manualQuantity,
    'material': material,
    'color': color,
    'thickness': thickness,
    'sheetWidth': sheetWidth,
    'sheetHeight': sheetHeight,
    'waste': waste,
  };
  factory CostLine.fromJson(Map<String, dynamic> j) => CostLine(
    id: j['id'],
    name: j['name'],
    group: j['group'],
    unit: j['unit'],
    price: j['price'],
    manualQuantity: (j['quantity'] as num?)?.toDouble(),
    material: j['material'] ?? '',
    color: j['color'] ?? '',
    thickness: (j['thickness'] as num? ?? 18).toDouble(),
    sheetWidth: (j['sheetWidth'] as num? ?? 2800).toDouble(),
    sheetHeight: (j['sheetHeight'] as num? ?? 2070).toDouble(),
    waste: (j['waste'] as num? ?? 10).toDouble(),
  );
}

class Estimate {
  String name = 'Жаңа есеп', client = '', notes = '';
  bool kitchen = false, corner = false, sliding = false, upper = true;
  double width = 1800,
      second = 1200,
      height = 2400,
      depth = 600,
      upperHeight = 720,
      upperDepth = 320;
  int sectionCount = 3;
  String coefficient = '1,5', discount = '0';
  bool discountPercent = true;
  List<CabinetSection> sections = [];
  List<CostLine> lines = [];
  Estimate() {
    rebuild();
  }
  void rebuild() {
    sections = [];
    for (var wing = 1; wing <= (corner ? 2 : 1); wing++) {
      // The second wing is measured from the end of the first wing, no overlap.
      final length = wing == 1 ? width : second;
      for (var i = 0; i < sectionCount; i++) {
        sections.add(
          CabinetSection(
            width: length / sectionCount,
            height: height,
            depth: depth,
            shelves: kitchen ? 1 : 3,
            doors: 1,
            level: kitchen ? 'Төменгі' : 'Корпус',
            wing: wing,
          ),
        );
        if (kitchen && upper) {
          sections.add(
            CabinetSection(
              width: length / sectionCount,
              height: upperHeight,
              depth: upperDepth,
              shelves: 2,
              doors: 1,
              level: 'Жоғарғы',
              wing: wing,
            ),
          );
        }
      }
    }
    final defaults = <CostLine>[
      CostLine(
        id: 'body',
        name: 'Корпус',
        group: 'Материалдар',
        unit: 'м²',
        material: 'ЛДСП',
      ),
      CostLine(
        id: 'front',
        name: 'Қасбет',
        group: 'Материалдар',
        unit: 'м²',
        material: 'МДФ',
      ),
      CostLine(
        id: 'back',
        name: 'Артқы қабырға',
        group: 'Материалдар',
        unit: 'м²',
        material: 'ХДФ',
        thickness: 3,
      ),
      CostLine(
        id: 'edge',
        name: 'Жиек таспасы',
        group: 'Материалдар',
        unit: 'пог. м',
        material: 'ПВХ',
        thickness: 1,
      ),
      if (kitchen) ...[
        CostLine(
          id: 'top',
          name: 'Жұмыс үстелі',
          group: 'Материалдар',
          unit: 'пог. м',
          thickness: 38,
        ),
        CostLine(
          id: 'panel',
          name: 'Қабырға панелі',
          group: 'Материалдар',
          unit: 'м²',
        ),
        CostLine(
          id: 'plinth',
          name: 'Плинтус',
          group: 'Материалдар',
          unit: 'пог. м',
        ),
      ],
      for (final item in [
        ['hinges', 'Топсалар'],
        ['handles', 'Тұтқалар'],
        ['runners', 'Тартпа бағыттауыштары (жұп)'],
        ['mechanism', 'Тартпа механизмдері'],
        ['legs', 'Аяқшалар'],
        ['rail', 'Киім ілетін штанга'],
        ['sliding', 'Жылжымалы есік механизмі (жиынтық)'],
        ['fasteners', 'Бекіткіштер (жиынтық)'],
      ])
        CostLine(
          id: item[0],
          name: item[1],
          group: 'Фурнитура',
          unit: item[0] == 'rail' ? 'пог. м' : 'дана',
        ),
      for (final item in [
        ['cut', 'Кесу'],
        ['edging', 'Жиектеу'],
        ['assembly', 'Жинау'],
        ['delivery', 'Жеткізу'],
        ['install', 'Орнату'],
      ])
        CostLine(
          id: item[0],
          name: item[1],
          group: 'Жұмыстар',
          unit: item[0] == 'edging' ? 'пог. м' : 'дана',
        ),
    ];
    final old = {for (final l in lines) l.id: l};
    lines = [
      for (final l in defaults) old[l.id] ?? l,
      ...lines.where((l) => l.id.startsWith('custom-')),
    ];
  }

  /// Approximate independent box modules, not a nesting/cutting optimizer.
  Map<String, double> quantities() {
    double body = 0,
        front = 0,
        back = 0,
        edge = 0,
        length = 0,
        topArea = 0,
        doors = 0,
        drawers = 0,
        hinges = 0,
        legs = 0,
        rail = 0,
        pieces = 0;
    final t = lines.where((l) => l.id == 'body').first.thickness / 1000;
    for (final s in sections) {
      final w = s.width / 1000, h = s.height / 1000, d = s.depth / 1000;
      final inner = math.max(0.0, w - 2 * t);
      // Two sides, top/bottom, shelves. Drawer box: four sides at 150 mm + bottom.
      body +=
          2 * h * d +
          (2 + s.shelves) * inner * d +
          s.drawers * (2 * (inner + d) * .15 + inner * d);
      front += w * h;
      back += w * h;
      edge +=
          2 * h +
          (2 + s.shelves) * inner +
          2 * (w + h) +
          math.max(0, s.doors - 1) * 2 * h +
          s.drawers * 2 * (inner + d);
      doors += s.doors;
      drawers += s.drawers;
      hinges +=
          s.doors *
          (h > 2
              ? 4
              : h > 1
              ? 3
              : 2);
      pieces += 4 + s.shelves + s.drawers * 5;
      if (s.level != 'Жоғарғы') {
        length += w;
        topArea += w * d;
        legs += 4;
      }
      if (!kitchen) rail += inner;
    }
    return {
      'body': body,
      'front': front,
      'back': back,
      'edge': edge,
      'top': topArea,
      'panel': length * .6,
      'plinth': length,
      'length': length,
      'pieces': pieces,
      'doors': doors,
      'hinges': sliding && !kitchen ? 0 : hinges,
      'handles': doors + drawers,
      'runners': drawers,
      'mechanism': 0,
      'legs': legs,
      'rail': rail,
      'sliding': sliding && !kitchen ? (corner ? 2 : 1) : 0,
      'fasteners': sections.length.toDouble(),
      'cut': 1,
      'edging': edge,
      'assembly': 1,
      'delivery': 1,
      'install': 1,
    };
  }

  double suggested(CostLine l) {
    final q = quantities();
    var n = q[l.id] ?? 0;
    if (l.group == 'Материалдар') {
      if (l.unit == 'парақ') {
        final area = l.sheetWidth * l.sheetHeight / 1000000;
        if (area <= 0) return 0;
        return (n * (1 + l.waste / 100) / area).ceilToDouble();
      }
      if (l.unit == 'пог. м') n = l.id == 'edge' ? q['edge']! : q['length']!;
      if (l.unit == 'дана') {
        n = l.id == 'body'
            ? q['pieces']!
            : l.id == 'front'
            ? q['doors']!
            : sections.length.toDouble();
      }
      n *= 1 + l.waste / 100;
      if (l.unit == 'дана') n = n.ceilToDouble();
    }
    return n;
  }

  double quantity(CostLine l) => l.manualQuantity ?? suggested(l);
  int lineTotal(CostLine l) =>
      roundedProduct((quantity(l) * 1000000).round(), l.price ?? 0, 1000000);
  int groupTotal(String group) => lines
      .where((l) => l.group == group)
      .fold(0, (sum, l) => sum + lineTotal(l));
  int get cost => lines.fold(0, (sum, l) => sum + lineTotal(l));
  int get beforeDiscount =>
      roundedProduct(cost, decimal(coefficient) ?? 0, 1000000);
  int get discountTiyn => discountPercent
      ? roundedProduct(beforeDiscount, decimal(discount) ?? 0, 100000000)
      : decimal(discount, digits: 2) ?? 0;
  int get sale => beforeDiscount - discountTiyn;
  int get profit => sale - cost;
  List<CostLine> get unpriced =>
      lines.where((l) => quantity(l) > 0 && l.price == null).toList();
  String? validate() {
    if (name.trim().isEmpty) return 'Есеп атауын енгізіңіз';
    if ((decimal(coefficient) ?? 0) <= 0) {
      return 'Коэффициент нөлден үлкен болуы керек';
    }
    if (decimal(discount, digits: discountPercent ? 6 : 2) == null ||
        discountPercent && number(discount) > 100 ||
        discountTiyn > beforeDiscount) {
      return 'Жеңілдік сату бағасынан аспауы керек';
    }
    for (final s in sections) {
      if ([
            s.width,
            s.height,
            s.depth,
          ].any((v) => !v.isFinite || v <= 0 || v > 20000) ||
          s.width <= 2 * lines.first.thickness ||
          s.shelves < 0 ||
          s.doors < 0 ||
          s.drawers < 0) {
        return 'Секция өлшемдері жарамсыз';
      }
    }
    for (final l in lines) {
      if (l.name.trim().isEmpty ||
          l.price != null && l.price! < 0 ||
          l.manualQuantity != null &&
              (!l.manualQuantity!.isFinite || l.manualQuantity! < 0) ||
          l.waste < 0 ||
          l.waste > 100 ||
          l.sheetWidth <= 0 ||
          l.sheetHeight <= 0) {
        return 'Шығын жолын тексеріңіз';
      }
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
    'version': 1,
    'name': name,
    'client': client,
    'notes': notes,
    'kitchen': kitchen,
    'corner': corner,
    'sliding': sliding,
    'upper': upper,
    'width': width,
    'second': second,
    'height': height,
    'depth': depth,
    'upperHeight': upperHeight,
    'upperDepth': upperDepth,
    'sectionCount': sectionCount,
    'coefficient': coefficient,
    'discount': discount,
    'discountPercent': discountPercent,
    'sections': sections.map((s) => s.toJson()).toList(),
    'lines': lines.map((l) => l.toJson()).toList(),
  };
  factory Estimate.fromJson(Map<String, dynamic> j) {
    final e = Estimate();
    e.name = j['name'];
    e.client = j['client'];
    e.notes = j['notes'];
    e.kitchen = j['kitchen'];
    e.corner = j['corner'];
    e.sliding = j['sliding'];
    e.upper = j['upper'];
    e.width = (j['width'] as num).toDouble();
    e.second = (j['second'] as num).toDouble();
    e.height = (j['height'] as num).toDouble();
    e.depth = (j['depth'] as num).toDouble();
    e.upperHeight = (j['upperHeight'] as num).toDouble();
    e.upperDepth = (j['upperDepth'] as num).toDouble();
    e.sectionCount = j['sectionCount'];
    e.coefficient = j['coefficient'];
    e.discount = j['discount'];
    e.discountPercent = j['discountPercent'];
    e.sections = (j['sections'] as List)
        .map((v) => CabinetSection.fromJson(Map<String, dynamic>.from(v)))
        .toList();
    e.lines = (j['lines'] as List)
        .map((v) => CostLine.fromJson(Map<String, dynamic>.from(v)))
        .toList();
    return e;
  }
}
