import '../../core/widgets/app_back_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/router/route_paths.dart';
import '../../core/theme/glass/liquid_glass.dart';
import '../auth/presentation/providers/auth_providers.dart';
import '../orders/presentation/widgets/order_client_picker_sheet.dart';
import 'measurement_repository.dart';
import '../orders/presentation/providers/order_providers.dart';
import 'measurement_strings.dart';
import 'measurement_gallery.dart';
import 'measurement_plan.dart';
import 'measurement_pdf.dart';
import 'package:printing/printing.dart';

class MeasurementForm extends ConsumerStatefulWidget {
  const MeasurementForm({super.key, this.existing});
  final Map<String, dynamic>? existing;
  @override
  ConsumerState<MeasurementForm> createState() => _MeasurementFormState();
}

class _MeasurementFormState extends ConsumerState<MeasurementForm> {
  final form = GlobalKey<FormState>();
  final fields = <String, TextEditingController>{};
  String? id, clientId, orderId;
  String clientName = '';
  List<MeasurementPhotoDraft> photos = [];
  int selectedPhoto = 0;
  Set<String> originalPaths = {};
  bool picking = false;
  bool rectangleTool = false;
  bool busy = false;
  RoomPlan plan = RoomPlan([]);
  @override
  void initState() {
    super.initState();
    final row = widget.existing ?? {};
    id = row['id'] as String?;
    clientId = row['client_id'] as String?;
    clientName = (row['client'] as Map?)?['name'] as String? ?? '';
    orderId = row['order_id'] as String?;
    photos = MeasurementPhotoDraft.fromRow(row);
    plan = RoomPlan.fromJson(row['room_plan'] as List?);
    originalPaths = photos.map((p) => p.path).whereType<String>().toSet();
    for (final key in [
      'address',
      'room_type',
      'material',
      'width',
      'height',
      'depth',
      'notes',
    ]) {
      fields[key] = TextEditingController(text: row[key]?.toString() ?? '');
    }
    fields['price'] = TextEditingController(
      text: row['estimated_amount_tiyn'] == null
          ? ''
          : ((row['estimated_amount_tiyn'] as num) / 100).toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    for (final c in fields.values) {
      c.dispose();
    }
    super.dispose();
  }

  void message(String value) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(value)));
  Future<void> pickPhoto() async {
    if (picking) return;
    setState(() => picking = true);
    final s = ref.read(measurementStringsProvider);
    try {
      final selected = await ImagePicker().pickMultiImage(
        maxWidth: 2400,
        imageQuality: 85,
      );
      for (final file in selected) {
        final bytes = await file.readAsBytes();
        if (!mounted) return;
        if (bytes.length > 10 * 1024 * 1024) {
          message(s.photoLimit);
          continue;
        }
        final ext = file.name.split('.').last.toLowerCase();
        if (!['jpg', 'jpeg', 'png', 'webp'].contains(ext)) {
          message(s.error);
          continue;
        }
        setState(() {
          photos.add(MeasurementPhotoDraft(bytes: bytes, extension: ext));
          selectedPhoto = photos.length - 1;
        });
      }
    } catch (_) {
      if (mounted) message(s.error);
    } finally {
      if (mounted) setState(() => picking = false);
    }
  }

  void removePhoto() {
    final s = ref.read(measurementStringsProvider);
    final index = selectedPhoto;
    final removed = photos[index];
    setState(() {
      photos.removeAt(index);
      selectedPhoto = photos.isEmpty ? 0 : index.clamp(0, photos.length - 1);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(s.photoRemoved),
        action: SnackBarAction(
          label: s.restorePhoto,
          onPressed: () {
            if (!mounted || busy) return;
            setState(() {
              final at = index.clamp(0, photos.length);
              photos.insert(at, removed);
              selectedPhoto = at;
            });
          },
        ),
      ),
    );
  }

  Future<void> addArrow(Offset start, Offset end) async {
    final s = ref.read(measurementStringsProvider);
    final target = photos[selectedPhoto];
    final controller = TextEditingController();
    final label = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.arrowLabel),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 40,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text(s.save),
          ),
        ],
      ),
    );
    // The dialog's exit animation can still reference its controller.
    await Future<void>.delayed(const Duration(milliseconds: 250));
    controller.dispose();
    if (!mounted ||
        label == null ||
        label.isEmpty ||
        !photos.contains(target)) {
      return;
    }
    setState(
      () => target.annotations = [
        ...target.annotations,
        {
          'x1': start.dx,
          'y1': start.dy,
          'x2': end.dx,
          'y2': end.dy,
          'label': label,
          'shape': rectangleTool ? 'rectangle' : 'arrow',
        },
      ],
    );
  }

  Future<void> save({bool convert = false}) async {
    if (busy) return;
    final s = ref.read(measurementStringsProvider);
    if (!(form.currentState?.validate() ?? false)) return;
    if (!plan.valid) {
      message(s.invalidPlan);
      return;
    }
    if (clientId == null) {
      message(s.client);
      return;
    }
    final company = ref.read(currentUserProvider)?.companyId;
    if (company == null) {
      message(s.error);
      return;
    }
    setState(() => busy = true);
    final repo = ref.read(measurementRepositoryProvider);
    final uploaded = <String>[];
    final staged = <Map<String, dynamic>>[];
    bool persisted = false;
    try {
      for (var i = 0; i < photos.length; i++) {
        final photo = photos[i];
        var path = photo.path;
        if (photo.bytes != null) {
          path =
              '$company/${DateTime.now().microsecondsSinceEpoch}-$i.${photo.extension}';
          await repo.client.storage
              .from('measurement-photos')
              .uploadBinary(
                path,
                photo.bytes!,
                fileOptions: FileOptions(
                  contentType: photo.extension == 'png'
                      ? 'image/png'
                      : photo.extension == 'webp'
                      ? 'image/webp'
                      : 'image/jpeg',
                ),
              );
          uploaded.add(path);
        }
        staged.add({'path': path, 'annotations': photo.annotations});
      }
      final data = <String, dynamic>{
        'company_id': company,
        'client_id': clientId,
        for (final key in ['address', 'room_type', 'material', 'notes'])
          key: fields[key]!.text.trim(),
        for (final key in ['width', 'height', 'depth'])
          key: num.parse(fields[key]!.text.trim().replaceAll(',', '.')),
        'estimated_amount_tiyn': measurementPriceTiyn(fields['price']!.text),
        'photo_path': staged.isEmpty ? null : staged.first['path'],
        'photo_annotations': staged.isEmpty ? [] : staged.first['annotations'],
        'photo_gallery': staged,
        'room_plan': plan.toJson(),
      };
      final saved = await repo.save(id, data);
      persisted = true;
      id = saved['id'] as String;
      final removedPaths = originalPaths.difference(
        staged.map((p) => p['path'] as String).toSet(),
      );
      photos = MeasurementPhotoDraft.fromRow(saved);
      originalPaths = photos.map((p) => p.path!).toSet();
      if (removedPaths.isNotEmpty) {
        try {
          await repo.client.storage
              .from('measurement-photos')
              .remove(removedPaths.toList());
        } catch (_) {
          if (mounted) message(s.cleanupError);
        }
      }
      ref.invalidate(measurementsProvider);
      if (convert) {
        orderId = await repo.convert(id!);
        ref.invalidate(measurementsProvider);
        ref.invalidate(ordersListProvider);
        ref.invalidate(orderDetailProvider(orderId!));
      }
      if (!mounted) return;
      message(s.saved);
      if (convert && orderId != null) {
        final router = GoRouter.of(context);
        Navigator.pop(context);
        router.go(RoutePaths.orderDetail(orderId!));
      } else {
        Navigator.pop(context);
      }
    } catch (_) {
      if (!persisted && uploaded.isNotEmpty) {
        try {
          await repo.client.storage.from('measurement-photos').remove(uploaded);
        } catch (_) {
          /* A later storage cleanup can remove an orphan. */
        }
      }
      if (mounted) message(s.error);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> exportPdf() async {
    final s = ref.read(measurementStringsProvider);
    if (!plan.valid) {
      message(s.invalidPlan);
      return;
    }
    setState(() => busy = true);
    try {
      final repo = ref.read(measurementRepositoryProvider);
      final bytes = await buildMeasurementPdf(
        strings: s,
        clientName: clientName,
        fields: fields.map((key, value) => MapEntry(key, value.text)),
        plan: plan,
        photos: photos,
        download: (path) =>
            repo.client.storage.from('measurement-photos').download(path),
      );
      if (!mounted) return;
      await Printing.layoutPdf(
        name: 'JUMA-measurement.pdf',
        onLayout: (_) async => bytes,
      );
    } catch (_) {
      if (mounted) message(s.error);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(measurementStringsProvider);
    Widget field(
      String key,
      String label, {
      bool dimension = false,
      bool required = false,
    }) => TextFormField(
      controller: fields[key],
      enabled: !busy,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: dimension ? const TextStyle(fontSize: 12) : null,
      ),
      keyboardType: dimension || key == 'price'
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      maxLines: key == 'notes' ? 3 : 1,
      validator: (v) {
        if (dimension) {
          final n = num.tryParse((v ?? '').replaceAll(',', '.'));
          if (n == null || !n.isFinite || n <= 0) return s.positive;
        }
        if (key == 'price' && measurementPriceTiyn(v ?? '') == null) {
          return s.priceError;
        }
        if (required && (v ?? '').trim().isEmpty) return s.required;
        return null;
      },
    );
    return Scaffold(
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (busy)
                const Center(child: CircularProgressIndicator())
              else ...[
                FilledButton.icon(
                  onPressed: picking ? null : () => save(),
                  icon: const Icon(Icons.check),
                  label: Text(s.save),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: picking
                      ? null
                      : () {
                          if (orderId != null) {
                            final router = GoRouter.of(context);
                            Navigator.pop(context);
                            router.go(RoutePaths.orderDetail(orderId!));
                          } else {
                            save(convert: true);
                          }
                        },
                  icon: const Icon(Icons.assignment_outlined),
                  label: Text(orderId == null ? s.order : s.openOrder),
                ),
              ],
            ],
          ),
        ),
      ),
      appBar: AppBar(
        leading: const AppBackButton(),
        title: Text(s.sheet),
        actions: [
          IconButton(
            tooltip: s.exportPdf,
            onPressed: busy || picking ? null : exportPdf,
            icon: const Icon(Icons.picture_as_pdf_outlined),
          ),
        ],
      ),
      body: AbsorbPointer(
        absorbing: busy || picking,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Form(
              key: form,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    LiquidGlass(
                      padding: const EdgeInsets.all(16),
                      child: MeasurementGallery(
                        rectangle: rectangleTool,
                        onToolChanged: (value) =>
                            setState(() => rectangleTool = value),
                        photos: photos,
                        selected: selectedPhoto,
                        onSelect: (index) =>
                            setState(() => selectedPhoto = index),
                        onAdd: pickPhoto,
                        onDelete: removePhoto,
                        onArrow: addArrow,
                        onUndo: () => setState(() {
                          final p = photos[selectedPhoto];
                          p.annotations = p.annotations.sublist(
                            0,
                            p.annotations.length - 1,
                          );
                        }),
                      ),
                    ),
                    if (picking) const LinearProgressIndicator(),
                    const SizedBox(height: 20),
                    LiquidGlass(
                      padding: const EdgeInsets.all(16),
                      child: MeasurementPlanEditor(
                        plan: plan,
                        onChanged: (value) => setState(() => plan = value),
                      ),
                    ),
                    const SizedBox(height: 24),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final client = await OrderClientPickerSheet.open(
                          context,
                        );
                        if (client != null && mounted) {
                          setState(() {
                            clientId = client.id;
                            clientName = client.name;
                            if (fields['address']!.text.isEmpty) {
                              fields['address']!.text = client.address ?? '';
                            }
                          });
                        }
                      },
                      icon: const Icon(Icons.person_outline),
                      label: Text(clientName.isEmpty ? s.client : clientName),
                    ),
                    const SizedBox(height: 16),
                    field('address', s.address),
                    const SizedBox(height: 16),
                    field('room_type', s.product, required: true),
                    const SizedBox(height: 16),
                    field('material', s.material),
                    const SizedBox(height: 22),
                    LayoutBuilder(
                      builder: (_, c) {
                        final children = [
                          field('width', s.width, dimension: true),
                          field('height', s.height, dimension: true),
                          field('depth', s.depth, dimension: true),
                        ];
                        return c.maxWidth < 350
                            ? Column(
                                children: [
                                  for (final child in children)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 12,
                                      ),
                                      child: child,
                                    ),
                                ],
                              )
                            : Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  for (var i = 0; i < children.length; i++) ...[
                                    if (i > 0) const SizedBox(width: 10),
                                    Expanded(child: children[i]),
                                  ],
                                ],
                              );
                      },
                    ),
                    const SizedBox(height: 22),
                    LiquidGlass(
                      padding: const EdgeInsets.all(20),
                      child: field('price', s.amount),
                    ),
                    const SizedBox(height: 18),
                    field('notes', s.notes),
                    const SizedBox(height: 24),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
