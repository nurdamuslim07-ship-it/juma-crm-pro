import '../../core/widgets/app_back_button.dart';
import '../../core/widgets/press_motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/glass/liquid_glass.dart';
import 'measurement_repository.dart';
import 'measurement_strings.dart';
import 'measurement_form.dart';

class MeasurementsScreen extends ConsumerStatefulWidget {
  const MeasurementsScreen({super.key});
  @override
  ConsumerState<MeasurementsScreen> createState() => _MeasurementsScreenState();
}

class _MeasurementsScreenState extends ConsumerState<MeasurementsScreen> {
  String query = '';
  Future<void> open([Map<String, dynamic>? row]) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => MeasurementForm(existing: row)),
    );
    ref.invalidate(measurementsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(measurementStringsProvider);
    final data = ref.watch(measurementsProvider);
    return Scaffold(
      appBar: AppBar(leading: const AppBackButton(), title: Text(s.title)),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(measurementsProvider);
          await ref.read(measurementsProvider.future);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          children: [
            LiquidGlass(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  TextField(
                    onChanged: (v) =>
                        setState(() => query = v.toLowerCase().trim()),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: s.search,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => open(),
                      icon: const Icon(Icons.add),
                      label: Text(s.add),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            data.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => Column(
                children: [
                  Text(s.error),
                  TextButton(
                    onPressed: () => ref.invalidate(measurementsProvider),
                    child: Text(s.retry),
                  ),
                ],
              ),
              data: (rows) {
                final filtered = rows
                    .where(
                      (r) =>
                          '${(r['client'] as Map?)?['name'] ?? ''} ${r['address'] ?? ''}'
                              .toLowerCase()
                              .contains(query),
                    )
                    .toList();
                if (filtered.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(40),
                    child: Center(
                      child: Text(rows.isEmpty ? s.empty : s.noResults),
                    ),
                  );
                }
                final groups = <String, List<Map<String, dynamic>>>{};
                for (final r in filtered) {
                  final date = DateTime.parse(
                    r['created_at'] as String,
                  ).toLocal();
                  final key = DateFormat.yMMMM(s.ru ? 'ru' : 'kk').format(date);
                  groups.putIfAbsent(key, () => []).add(r);
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final group in groups.entries) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          '${group.key} · ${group.value.length}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final width = constraints.maxWidth;
                          final columns = width >= 1000
                              ? 3
                              : width >= 650
                              ? 2
                              : 1;
                          return Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              for (final r in group.value)
                                SizedBox(
                                  width: (width - (columns - 1) * 12) / columns,
                                  child: MotionInkWell(
                                    borderRadius: BorderRadius.circular(20),
                                    onTap: () => open(r),
                                    child: LiquidGlass(
                                      padding: const EdgeInsets.all(14),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              SizedBox(
                                                width: 56,
                                                height: 56,
                                                child: ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(14),
                                                  child: ColoredBox(
                                                    color: Colors.teal
                                                        .withValues(alpha: .1),
                                                    child:
                                                        r['photo_path'] == null
                                                        ? const Icon(
                                                            Icons.straighten,
                                                            color: Colors.teal,
                                                            size: 28,
                                                          )
                                                        : ref
                                                              .watch(
                                                                measurementPhotoUrlProvider(
                                                                  r['photo_path']
                                                                      as String,
                                                                ),
                                                              )
                                                              .when(
                                                                data: (url) => Image.network(
                                                                  url,
                                                                  fit: BoxFit
                                                                      .cover,
                                                                  errorBuilder:
                                                                      (
                                                                        _,
                                                                        _,
                                                                        _,
                                                                      ) => const Icon(
                                                                        Icons
                                                                            .broken_image_outlined,
                                                                      ),
                                                                ),
                                                                loading: () =>
                                                                    const Center(
                                                                      child:
                                                                          CircularProgressIndicator(),
                                                                    ),
                                                                error: (_, _) =>
                                                                    const Icon(
                                                                      Icons
                                                                          .broken_image_outlined,
                                                                    ),
                                                              ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      (r['client']
                                                                  as Map?)?['name']
                                                              as String? ??
                                                          '—',
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .titleMedium
                                                          ?.copyWith(
                                                            fontWeight:
                                                                FontWeight.w700,
                                                          ),
                                                    ),
                                                    const SizedBox(height: 3),
                                                    Text(
                                                      r['address'] as String? ??
                                                          '',
                                                      maxLines: 2,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: Theme.of(
                                                        context,
                                                      ).textTheme.bodySmall,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                DateFormat('dd.MM').format(
                                                  DateTime.parse(
                                                    r['created_at'] as String,
                                                  ).toLocal(),
                                                ),
                                                style: Theme.of(
                                                  context,
                                                ).textTheme.bodySmall,
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            '${r['width'] ?? '—'} × ${r['height'] ?? '—'} × ${r['depth'] ?? '—'} мм',
                                            style: const TextStyle(
                                              color: Colors.teal,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  r['room_type'] as String? ??
                                                      '',
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: Theme.of(
                                                    context,
                                                  ).textTheme.bodySmall,
                                                ),
                                              ),
                                              Text(
                                                '${NumberFormat.decimalPattern().format(((r['estimated_amount_tiyn'] as num?) ?? 0) / 100)} ₸',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleSmall
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                              ),
                                              const SizedBox(width: 8),
                                              const Icon(
                                                Icons.chevron_right,
                                                size: 18,
                                                color: Colors.teal,
                                              ),
                                            ],
                                          ),
                                          if (r['order_id'] != null)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                top: 8,
                                              ),
                                              child: Text(
                                                s.openOrder,
                                                style: const TextStyle(
                                                  color: Colors.teal,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ],
                  ],
                );
              },
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
