import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/widgets/app_back_button.dart';
import '../../core/widgets/glass_card.dart';
import 'estimate_model.dart';
import 'estimate_repository.dart';

String money(int tiyn) =>
    '${NumberFormat('#,##0.##', 'kk').format(tiyn / 100)} ₸';

class EstimateScreen extends ConsumerWidget {
  const EstimateScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Future<void> open({Map<String, dynamic>? row, bool copy = false}) async {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => EstimateEditor(row: row, copy: copy),
        ),
      );
      ref.invalidate(estimateListProvider);
    }

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text('Тез есеп'),
        actions: [
          IconButton(
            tooltip: 'Баға анықтамалығы',
            icon: const Icon(Icons.price_change_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PriceCatalogScreen()),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => open(),
        icon: const Icon(Icons.add),
        label: const Text('Жаңа есеп'),
      ),
      body: ref
          .watch(estimateListProvider)
          .when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => Center(
              child: TextButton(
                onPressed: () => ref.invalidate(estimateListProvider),
                child: const Text('Есептер жүктелмеді. Қайталау'),
              ),
            ),
            data: (rows) => rows.isEmpty
                ? const Center(
                    child: Text('Шкаф немесе асүйдің алғашқы есебін жасаңыз'),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                    itemCount: rows.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final row = rows[i];
                      final e = Estimate.fromJson(
                        Map<String, dynamic>.from(row['snapshot']),
                      );
                      return GlassCard(
                        onTap: () => open(row: row),
                        child: Row(
                          children: [
                            const Icon(Icons.calculate_outlined),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    e.name,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                  Text(e.client),
                                  Text(
                                    '${money(e.sale)}${e.unpriced.isEmpty ? '' : ' · Толық емес'}',
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: 'Көшірмесін жасау',
                              onPressed: () => open(row: row, copy: true),
                              icon: const Icon(Icons.copy_outlined),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
    );
  }
}

class EstimateEditor extends ConsumerStatefulWidget {
  const EstimateEditor({super.key, this.row, this.copy = false});
  final Map<String, dynamic>? row;
  final bool copy;
  @override
  ConsumerState<EstimateEditor> createState() => _EstimateEditorState();
}

class _EstimateEditorState extends ConsumerState<EstimateEditor> {
  late Estimate e;
  String? id;
  bool busy = false, loading = true;
  int generation = 0;
  final invalid = <String>{};
  List<CostLine> catalog = [];
  @override
  void initState() {
    super.initState();
    e = widget.row == null
        ? Estimate()
        : Estimate.fromJson(Map<String, dynamic>.from(widget.row!['snapshot']));
    id = widget.copy ? null : widget.row?['id'];
    if (widget.copy) e.name += ' — көшірме';
    loadCatalog();
  }

  void rebuildModel() {
    final existing = e.lines.map((l) => l.id).toSet();
    e.rebuild();
    for (var i = 0; i < e.lines.length; i++) {
      if (existing.contains(e.lines[i].id)) continue;
      final matches = catalog.where((l) => l.id == e.lines[i].id);
      if (matches.isNotEmpty) {
        e.lines[i] = CostLine.fromJson(matches.first.toJson());
      }
    }
  }

  Future<void> loadCatalog() async {
    try {
      catalog = await ref
          .read(estimateRepositoryProvider)
          .catalog()
          .timeout(const Duration(seconds: 12));
      if (widget.row == null) applyCatalog();
    } catch (_) {
      if (mounted) {
        message('Анықтамалық жүктелмеді. Бағаларды қолмен енгізуге болады.');
      }
    }
    if (mounted) setState(() => loading = false);
  }

  void applyCatalog() {
    final byId = {for (final l in catalog) l.id: l};
    for (var i = 0; i < e.lines.length; i++) {
      final l = byId[e.lines[i].id];
      if (l != null) e.lines[i] = CostLine.fromJson(l.toJson());
    }
  }

  Future<void> pickPrice(CostLine target) async {
    try {
      final entries = await ref.read(estimateRepositoryProvider).catalog();
      if (!mounted) return;
      final selected = await showDialog<CostLine>(
        context: context,
        builder: (context) => SimpleDialog(
          title: const Text('Анықтамалықтан таңдау'),
          children: [
            if (entries.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Әзірге бағалар сақталмаған'),
              ),
            for (final l in entries.where((l) => l.group == target.group))
              SimpleDialogOption(
                onPressed: () => Navigator.pop(context, l),
                child: Text(
                  '${l.name} · ${l.material} · ${l.unit} · ${l.price == null ? 'Баға жоқ' : money(l.price!)}',
                ),
              ),
          ],
        ),
      );
      if (selected != null && mounted) {
        setState(() {
          final replacement = CostLine.fromJson(selected.toJson())
            ..id = target.id
            ..manualQuantity = target.manualQuantity;
          e.lines[e.lines.indexOf(target)] = replacement;
          invalid.removeWhere((key) => key.startsWith('${target.id}-'));
          generation++;
        });
      }
    } catch (_) {
      if (mounted) message('Анықтамалық жүктелмеді');
    }
  }

  void message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  Widget text(
    String key,
    String label,
    String value,
    void Function(String) change, {
    bool numeric = false,
    bool integer = false,
    bool positive = false,
    bool optional = false,
    double? max,
    int digits = 6,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        key: ValueKey('$generation-$key'),
        initialValue: value,
        keyboardType: numeric
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        decoration: InputDecoration(labelText: label),
        autovalidateMode: AutovalidateMode.onUserInteraction,
        validator: (v) {
          if (!numeric) return null;
          if (optional && (v ?? '').isEmpty) return null;
          final n = decimal(v ?? '', digits: integer ? 0 : digits);
          return n == null ||
                  positive && n == 0 ||
                  max != null && number(v!) > max
              ? 'Жарамды ${positive ? 'оң ' : ''}сан енгізіңіз'
              : null;
        },
        onChanged: (v) {
          final n = numeric ? decimal(v, digits: integer ? 0 : digits) : 0;
          final bad =
              numeric &&
              !(optional && v.isEmpty) &&
              (n == null ||
                  positive && n == 0 ||
                  max != null && number(v) > max);
          setState(() {
            if (bad) {
              invalid.add(key);
            } else {
              invalid.remove(key);
              change(v);
            }
          });
        },
      ),
    );
  }

  Widget numField(
    String key,
    String label,
    double value,
    void Function(double) change, {
    bool positive = false,
    bool integer = false,
    double? max,
  }) => text(
    key,
    label,
    qty(value),
    (v) => change(number(v)),
    numeric: true,
    positive: positive,
    integer: integer,
    max: max,
  );
  Widget choice<T>(
    String label,
    T value,
    List<T> options,
    String Function(T) name,
    void Function(T) change,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: options
          .map((v) => DropdownMenuItem(value: v, child: Text(name(v))))
          .toList(),
      onChanged: (v) {
        if (v != null) setState(() => change(v));
      },
    ),
  );
  Future<void> rebuild() async {
    if (invalid.isNotEmpty) {
      message('Алдымен жарамсыз өрістерді түзетіңіз');
      return;
    }
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Секцияларды жаңарту'),
        content: const Text(
          'Жеке секция өлшемдері стандарт бойынша қайта құрылады. Қолмен түзетілген шығын мөлшерлері сақталады.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Бас тарту'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Жаңарту'),
          ),
        ],
      ),
    );
    if (accepted == true && mounted) {
      setState(() {
        rebuildModel();
        generation++;
      });
    }
  }

  Future<void> save() async {
    if (busy) return;
    final error = e.validate();
    if (invalid.isNotEmpty || error != null) {
      message(error ?? 'Жарамсыз өрістерді түзетіңіз');
      return;
    }
    setState(() => busy = true);
    try {
      id = await ref.read(estimateRepositoryProvider).save(id, e);
      if (mounted) {
        message(
          'Есеп сақталды${e.unpriced.isEmpty ? '' : ' (бағалары толық емес)'}',
        );
      }
    } catch (_) {
      if (mounted) message('Сақталмады. Байланыс пен рұқсатты тексеріңіз');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        appBar: AppBar(
          leading: const AppBackButton(),
          title: const Text("Тез есеп"),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text('Тез есеп'),
        actions: [
          IconButton(
            tooltip: 'Сақтау',
            onPressed: busy ? null : save,
            icon: const Icon(Icons.save_outlined),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: GlassCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Материал: ${money(e.groupTotal('Материалдар'))} · Фурнитура: ${money(e.groupTotal('Фурнитура'))}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  'Жұмыс/қосымша: ${money(e.groupTotal('Жұмыстар') + e.groupTotal('Қосымша шығындар'))} · ×${e.coefficient} · Жеңілдік: ${money(e.discountTiyn)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  'Клиентке: ${money(e.sale)}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  'Өзіндік құн: ${money(e.cost)} · Пайда: ${money(e.profit)}',
                ),
                if (invalid.isNotEmpty || e.validate() != null)
                  const Text(
                    'Жарамсыз мән бар — нәтиже соңғы жарамды мәндермен көрсетілген',
                    style: TextStyle(color: Colors.red),
                  ),
                if (e.unpriced.isNotEmpty)
                  Text(
                    'Толық емес: ${e.unpriced.length} позицияның бағасы жоқ',
                    style: const TextStyle(color: Colors.orange),
                  ),
              ],
            ),
          ),
        ),
      ),
      body: AbsorbPointer(
        absorbing: busy,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 850),
              child: Column(
                children: [
                  text('name', 'Есеп атауы', e.name, (v) => e.name = v),
                  text('client', 'Клиент аты', e.client, (v) => e.client = v),
                  text('notes', 'Ескертпе', e.notes, (v) => e.notes = v),
                  ExpansionTile(
                    initiallyExpanded: true,
                    title: const Text('1. Жиһаз және құрылым'),
                    children: [
                      choice(
                        'Жиһаз түрі',
                        e.kitchen,
                        [false, true],
                        (v) => v ? 'Асүй' : 'Шкаф',
                        (v) {
                          e.kitchen = v;
                          e.height = v ? 720 : 2400;
                          rebuildModel();
                          generation++;
                        },
                      ),
                      choice(
                        'Пішіні',
                        e.corner,
                        [false, true],
                        (v) => v ? 'Бұрышты' : 'Түзу',
                        (v) {
                          e.corner = v;
                          rebuildModel();
                          generation++;
                        },
                      ),
                      if (!e.kitchen)
                        choice(
                          'Есік түрі',
                          e.sliding,
                          [false, true],
                          (v) => v ? 'Жылжымалы' : 'Ашпалы',
                          (v) => e.sliding = v,
                        ),
                      if (e.kitchen)
                        SwitchListTile(
                          title: const Text('Жоғарғы шкафтар'),
                          value: e.upper,
                          onChanged: (v) => setState(() {
                            e.upper = v;
                            rebuildModel();
                            generation++;
                          }),
                        ),
                      const Text(
                        'Жалпы өлшем өзгерсе, секциялар автоматты түрде қайта бөлінеді. Жеке баптауды одан кейін жасаңыз. Қолмен түзетілген шығын мөлшері автоматты өзгермейді.',
                      ),
                      const SizedBox(height: 12),
                      numField(
                        'width',
                        'Ені / бірінші жақ, мм',
                        e.width,
                        (v) {
                          e.width = v;
                          rebuildModel();
                        },
                        positive: true,
                        max: 20000,
                      ),
                      if (e.corner)
                        numField(
                          'second',
                          'Екінші жақтың таза ұзындығы, мм',
                          e.second,
                          (v) {
                            e.second = v;
                            rebuildModel();
                          },
                          positive: true,
                          max: 20000,
                        ),
                      numField(
                        'height',
                        e.kitchen
                            ? 'Төменгі корпус биіктігі, мм'
                            : 'Биіктігі, мм',
                        e.height,
                        (v) {
                          e.height = v;
                          rebuildModel();
                        },
                        positive: true,
                        max: 20000,
                      ),
                      numField(
                        'depth',
                        'Тереңдігі, мм',
                        e.depth,
                        (v) {
                          e.depth = v;
                          rebuildModel();
                        },
                        positive: true,
                        max: 5000,
                      ),
                      numField(
                        'count',
                        'Әр жақтағы секциялар саны',
                        e.sectionCount.toDouble(),
                        (v) {
                          e.sectionCount = v.toInt();
                          rebuildModel();
                        },
                        integer: true,
                        positive: true,
                        max: 30,
                      ),
                      if (e.kitchen && e.upper) ...[
                        numField(
                          'uh',
                          'Жоғарғы биіктігі, мм',
                          e.upperHeight,
                          (v) {
                            e.upperHeight = v;
                            rebuildModel();
                          },
                          positive: true,
                          max: 5000,
                        ),
                        numField(
                          'ud',
                          'Жоғарғы тереңдігі, мм',
                          e.upperDepth,
                          (v) {
                            e.upperDepth = v;
                            rebuildModel();
                          },
                          positive: true,
                          max: 2000,
                        ),
                      ],
                      OutlinedButton(
                        onPressed: rebuild,
                        child: const Text('Секцияларды жаңарту'),
                      ),
                      for (var i = 0; i < e.sections.length; i++) section(i),
                    ],
                  ),
                  for (final group in [
                    'Материалдар',
                    'Фурнитура',
                    'Жұмыстар',
                    'Қосымша шығындар',
                  ])
                    ExpansionTile(
                      title: Text('$group · ${money(e.groupTotal(group))}'),
                      children: [
                        for (final l in e.lines.where((l) => l.group == group))
                          line(l),
                        TextButton.icon(
                          onPressed: () => setState(
                            () => e.lines.add(
                              CostLine(
                                id: 'custom-${DateTime.now().microsecondsSinceEpoch}',
                                name: 'Жаңа позиция',
                                group: group,
                                manualQuantity: 1,
                              ),
                            ),
                          ),
                          icon: const Icon(Icons.add),
                          label: const Text('Позиция қосу'),
                        ),
                      ],
                    ),
                  ExpansionTile(
                    initiallyExpanded: true,
                    title: const Text('Баға және қорытынды'),
                    children: [
                      text(
                        'coefficient',
                        'Коэффициент',
                        e.coefficient,
                        (v) => e.coefficient = v,
                        numeric: true,
                        positive: true,
                        max: 100,
                      ),
                      const Text(
                        '1,5 коэффициенті = өзіндік құнға 50% үстеме.',
                      ),
                      const SizedBox(height: 12),
                      choice(
                        'Жеңілдік түрі',
                        e.discountPercent,
                        [true, false],
                        (v) => v ? 'Пайыз (%)' : 'Теңге (₸)',
                        (v) {
                          e.discountPercent = v;
                          e.discount = '0';
                          generation++;
                          invalid.remove('discount');
                        },
                      ),
                      text(
                        'discount',
                        'Жеңілдік',
                        e.discount,
                        (v) => e.discount = v,
                        numeric: true,
                        digits: e.discountPercent ? 6 : 2,
                        max: e.discountPercent ? 100 : null,
                      ),
                      for (final entry in {
                        'Материалдар': e.groupTotal('Материалдар'),
                        'Фурнитура': e.groupTotal('Фурнитура'),
                        'Жұмыс және қосымша':
                            e.groupTotal('Жұмыстар') +
                            e.groupTotal('Қосымша шығындар'),
                        'Жалпы өзіндік құн': e.cost,
                        'Жеңілдікке дейін': e.beforeDiscount,
                        'Жеңілдік': e.discountTiyn,
                        'Клиентке соңғы баға': e.sale,
                        'Есептік пайда': e.profit,
                      }.entries)
                        ListTile(
                          dense: true,
                          title: Text(entry.key),
                          subtitle: Text(money(entry.value)),
                        ),
                    ],
                  ),
                  const ExpansionTile(
                    title: Text('Формулалар мен болжамдар'),
                    children: [
                      Padding(
                        padding: EdgeInsets.all(12),
                        child: Text(
                          'Өлшемдер мм-ден метрге бөлінеді (÷1000). Әр секция — жеке корпус: 2 бүйір + үсті/асты + сөрелер. Ішкі ені = ені − 2 × корпус қалыңдығы. Корпус м² = 2×биіктік×тереңдік + (2+сөре)×ішкі ені×тереңдік. Тартпаға биіктігі 150 мм қораптың 4 жағы мен түбі қосылады.\n\nҚасбет пен артқы қабырға = ені×биіктігі. Қасбет ауданы тұтас жабық деп алынады, саңылаулар алынбайды; есік саны топса мен тұтқаға әсер етеді. Жиек: бүйірлердің алдыңғы қыры, көлденең бөлшектердің алдыңғы қыры, қасбет периметрі және есіктер арасы, тартпа периметрі.\n\nБұрыш: екінші қанаттың ұзындығын бірінші қанаттан кейінгі таза ұзындықпен енгізіңіз; бұрыш екі рет қосылмайды. Арнайы бұрыш модулі, ойық, ортақ қабырға мен кесу картасы есептелмейді.\n\nЖұмыс үстелі = төменгі модульдер ені×тереңдігі, погон метрде = ендерінің қосындысы. Панель биіктігі 600 мм. Плинтус = төменгі ендер қосындысы. Топса: есік биіктігі ≤1 м — 2, ≤2 м — 3, >2 м — 4. Әр төменгі корпусқа 4 аяқ, секцияға 1 бекіткіш жиынтығы. Штанга = шкаф секцияларының ішкі ені. Бағыттауыш жұбы = тартпа саны; қосымша механизм әдепкіде 0 (қайта есептемеңіз). Жылжымалы механизм әр қанатқа 1 жиынтық.\n\nМатериал қоры тек материал мөлшеріне қолданылады. Парақ саны = жоғарыға дөңгелектеу(м²×(1+қор/100) ÷ парақ ауданы). Бұл ШАМАМЕН есеп: бөлшектердің орналасуы мен талшық бағыты тексерілмейді. Дана бірлігінде корпус — панельдер саны, қасбет — есіктер саны; өзге материал — секциялар саны. Жиек пен плинтусты м²/парақпен есептемеңіз.\n\nҚолмен мөлшер берілсе, ол қорды қамтитын соңғы мөлшер ретінде алынады. Кесу, жинау, жеткізу, орнату — әрқайсысы бір жұмыс; жиектеу — таза жиек ұзындығы. Жалпы өзіндік құн = барлық жолдың мөлшері × бірлік бағасы. Сату = өзіндік құн × коэффициент − бір ғана жеңілдік. Пайда = сату − өзіндік құн. Ақша тиынға дейін дөңгелектеледі.',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: busy ? null : save,
                    icon: const Icon(Icons.save_outlined),
                    label: Text(busy ? 'Сақталуда…' : 'Есепті сақтау'),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget section(int i) {
    final s = e.sections[i];
    return ExpansionTile(
      key: ValueKey(
        'section-$generation-$i-${e.width}-${e.second}-${e.height}-${e.depth}-${e.upperHeight}-${e.upperDepth}-${e.sectionCount}',
      ),
      title: Text('${i + 1}. ${s.level} · ${s.wing}-жақ · ${qty(s.width)} мм'),
      children: [
        numField(
          's$i-w',
          'Ені, мм',
          s.width,
          (v) => s.width = v,
          positive: true,
          max: 20000,
        ),
        numField(
          's$i-h',
          'Биіктігі, мм',
          s.height,
          (v) => s.height = v,
          positive: true,
          max: 20000,
        ),
        numField(
          's$i-d',
          'Тереңдігі, мм',
          s.depth,
          (v) => s.depth = v,
          positive: true,
          max: 5000,
        ),
        numField(
          's$i-s',
          'Сөрелер',
          s.shelves.toDouble(),
          (v) => s.shelves = v.toInt(),
          integer: true,
          max: 100,
        ),
        numField(
          's$i-doors',
          'Есіктер',
          s.doors.toDouble(),
          (v) => s.doors = v.toInt(),
          integer: true,
          max: 30,
        ),
        numField(
          's$i-drawers',
          'Тартпалар',
          s.drawers.toDouble(),
          (v) => s.drawers = v.toInt(),
          integer: true,
          max: 30,
        ),
      ],
    );
  }

  Widget line(CostLine l) => ExpansionTile(
    key: ValueKey('line-$generation-${l.id}'),
    title: Text(l.name),
    subtitle: Text(
      '${qty(e.quantity(l))} ${l.unit} · ${l.price == null ? 'Бағасы жоқ' : money(e.lineTotal(l))}${l.manualQuantity == null ? '' : ' · қолмен'}',
    ),
    children: [
      text('${l.id}-name', 'Атауы', l.name, (v) => l.name = v),
      TextButton.icon(
        onPressed: () => pickPrice(l),
        icon: const Icon(Icons.price_change_outlined),
        label: const Text('Анықтамалықтан таңдау'),
      ),
      if (l.group == 'Материалдар') ...[
        text(
          '${l.id}-material',
          'Материал (ЛДСП, МДФ, акрил немесе өзге)',
          l.material,
          (v) => l.material = v,
        ),
        text('${l.id}-color', 'Түсі / түрі', l.color, (v) => l.color = v),
        numField(
          '${l.id}-thick',
          'Қалыңдығы, мм',
          l.thickness,
          (v) => l.thickness = v,
          positive: true,
          max: 100,
        ),
        numField(
          '${l.id}-waste',
          'Қор, %',
          l.waste,
          (v) => l.waste = v,
          max: 100,
        ),
      ],
      choice(
        'Есеп бірлігі',
        l.unit,
        l.id == 'edge' || l.id == 'plinth' || l.id == 'rail' || l.id == 'edging'
            ? ['пог. м', 'дана']
            : units,
        (v) => v,
        (v) => l.unit = v,
      ),
      if (l.unit == 'парақ') ...[
        const Text('Парақ саны — кесу картасынсыз шамамен есеп'),
        numField(
          '${l.id}-sw',
          'Парақ ені, мм',
          l.sheetWidth,
          (v) => l.sheetWidth = v,
          positive: true,
          max: 20000,
        ),
        numField(
          '${l.id}-sh',
          'Парақ биіктігі, мм',
          l.sheetHeight,
          (v) => l.sheetHeight = v,
          positive: true,
          max: 20000,
        ),
      ],
      Text('Автоматты мөлшер: ${qty(e.suggested(l))} ${l.unit}'),
      text(
        '${l.id}-quantity',
        'Мөлшерді қолмен түзету (бос = автоматты)',
        l.manualQuantity == null ? '' : qty(l.manualQuantity!),
        (v) => l.manualQuantity = v.isEmpty ? null : number(v),
        numeric: true,
        optional: true,
        max: 1000000,
      ),
      text(
        '${l.id}-price',
        'Бірлік өзіндік бағасы, ₸',
        l.price == null ? '' : qty(l.price! / 100),
        (v) {
          final p = v.isEmpty ? null : decimal(v, digits: 2);
          if (v.isNotEmpty && p == null) {
            invalid.add('${l.id}-price');
          } else {
            l.price = p;
          }
        },
        numeric: true,
        digits: 2,
        optional: true,
        max: 100000000,
      ),
      Text('Жалпы: ${money(e.lineTotal(l))}'),
      Wrap(
        spacing: 8,
        children: [
          TextButton(
            onPressed: invalid.isNotEmpty
                ? null
                : () async {
                    try {
                      await ref.read(estimateRepositoryProvider).savePrice(l);
                      if (mounted) {
                        message(
                          'Анықтамалыққа сақталды. Бұрынғы есептер өзгермейді.',
                        );
                      }
                    } catch (_) {
                      if (mounted) message('Анықтамалық сақталмады');
                    }
                  },
            child: const Text('Анықтамалыққа сақтау'),
          ),
          TextButton(
            onPressed: () => setState(() {
              l.manualQuantity = 0;
              generation++;
              invalid.remove('${l.id}-quantity');
            }),
            child: const Text('Есептен алып тастау (0)'),
          ),
        ],
      ),
    ],
  );
}

class PriceCatalogScreen extends ConsumerStatefulWidget {
  const PriceCatalogScreen({super.key});
  @override
  ConsumerState<PriceCatalogScreen> createState() => _PriceCatalogScreenState();
}

class _PriceCatalogScreenState extends ConsumerState<PriceCatalogScreen> {
  late Future<List<CostLine>> data;
  @override
  void initState() {
    super.initState();
    data = ref.read(estimateRepositoryProvider).catalog();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: const AppBackButton(),
      title: const Text('Баға анықтамалығы'),
    ),
    body: FutureBuilder<List<CostLine>>(
      future: data,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: TextButton(
              onPressed: () => setState(
                () => data = ref.read(estimateRepositoryProvider).catalog(),
              ),
              child: const Text('Қайталау'),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final rows = snapshot.data!;
        if (rows.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Есеп ішіндегі позицияны ашып, «Анықтамалыққа сақтау» басыңыз. Нақты бағалар ғана сақталады.',
              ),
            ),
          );
        }
        return ListView(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Бағаны өзгерту үшін позицияны басыңыз. Жаңа есепке автоматты қойылады; бұрын сақталған есеп өзгермейді.',
              ),
            ),
            for (final l in rows)
              ListTile(
                title: Text(l.name),
                subtitle: Text(
                  '${l.material} · ${l.unit} · ${l.price == null ? 'Баға жоқ' : money(l.price!)}',
                ),
                trailing: const Icon(Icons.edit_outlined),
                onTap: () => edit(l),
              ),
          ],
        );
      },
    ),
  );
  Future<void> edit(CostLine l) async {
    final controller = TextEditingController(
      text: l.price == null ? '' : qty(l.price! / 100),
    );
    final form = GlobalKey<FormState>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.name),
        content: Form(
          key: form,
          child: TextFormField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: 'Бір ${l.unit} бағасы, ₸'),
            validator: (v) => decimal(v ?? '', digits: 2) == null
                ? 'Жарамды баға енгізіңіз'
                : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Бас тарту'),
          ),
          FilledButton(
            onPressed: () {
              if (form.currentState!.validate()) Navigator.pop(context, true);
            },
            child: const Text('Сақтау'),
          ),
        ],
      ),
    );
    final value = decimal(controller.text, digits: 2);
    controller.dispose();
    if (ok != true) return;
    try {
      l.price = value;
      await ref.read(estimateRepositoryProvider).savePrice(l);
      if (mounted) {
        setState(() => data = ref.read(estimateRepositoryProvider).catalog());
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Баға сақталмады')));
      }
    }
  }
}
