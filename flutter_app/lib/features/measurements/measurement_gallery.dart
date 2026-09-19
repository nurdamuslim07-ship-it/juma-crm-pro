import '../../core/widgets/press_motion.dart';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'measurement_photo.dart';
import 'measurement_repository.dart';
import 'measurement_strings.dart';

class MeasurementPhotoDraft {
  MeasurementPhotoDraft({
    this.path,
    this.bytes,
    this.extension = 'jpg',
    List<Map<String, dynamic>>? annotations,
  }) : annotations = annotations ?? [];
  String? path;
  Uint8List? bytes;
  final String extension;
  List<Map<String, dynamic>> annotations;
  Map<String, dynamic> toJson() => {'path': path, 'annotations': annotations};
  static List<MeasurementPhotoDraft> fromRow(Map<String, dynamic> row) {
    final gallery = row['photo_gallery'] as List?;
    if (gallery != null) {
      return gallery
          .map(
            (e) => MeasurementPhotoDraft(
              path: e['path'] as String,
              annotations: (e['annotations'] as List? ?? [])
                  .map((a) => Map<String, dynamic>.from(a as Map))
                  .toList(),
            ),
          )
          .toList();
    }
    final path = row['photo_path'] as String?;
    return path == null
        ? []
        : [
            MeasurementPhotoDraft(
              path: path,
              annotations: (row['photo_annotations'] as List? ?? [])
                  .map((a) => Map<String, dynamic>.from(a as Map))
                  .toList(),
            ),
          ];
  }
}

class MeasurementGallery extends ConsumerWidget {
  const MeasurementGallery({
    super.key,
    required this.photos,
    required this.selected,
    required this.onSelect,
    required this.onAdd,
    required this.onDelete,
    required this.onArrow,
    required this.onUndo,
    this.rectangle = false,
    this.onToolChanged,
  });
  final bool rectangle;
  final ValueChanged<bool>? onToolChanged;
  final List<MeasurementPhotoDraft> photos;
  final int selected;
  final ValueChanged<int> onSelect;
  final VoidCallback onAdd, onDelete, onUndo;
  final void Function(Offset, Offset) onArrow;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(measurementStringsProvider);
    final photo = photos.isEmpty ? null : photos[selected];
    Widget preview(MeasurementPhotoDraft p, {bool thumbnail = false}) {
      Widget render(String? url) => thumbnail
          ? p.bytes != null
                ? Image.memory(p.bytes!, fit: BoxFit.cover, cacheWidth: 160)
                : Image.network(
                    url!,
                    fit: BoxFit.cover,
                    cacheWidth: 160,
                    errorBuilder: (_, _, _) =>
                        const Icon(Icons.broken_image_outlined),
                  )
          : MeasurementPhoto(
              key: ObjectKey(p),
              bytes: p.bytes,
              url: url,
              arrows: p.annotations,
              onArrow: onArrow,
            );
      if (p.bytes != null) return render(null);
      return ref
          .watch(measurementPhotoUrlProvider(p.path!))
          .when(
            data: render,
            loading: () => const AspectRatio(
              aspectRatio: 4 / 3,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, _) => Center(
              child: TextButton.icon(
                onPressed: () =>
                    ref.invalidate(measurementPhotoUrlProvider(p.path!)),
                icon: const Icon(Icons.refresh),
                label: Text(s.retry),
              ),
            ),
          );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(Icons.photo_library_outlined, color: Colors.teal),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${s.photos} · ${photos.length}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (photo == null)
          const SizedBox(
            height: 110,
            child: Icon(
              Icons.add_photo_alternate_outlined,
              size: 48,
              color: Colors.teal,
            ),
          )
        else ...[
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: Text(s.arrow),
                selected: !rectangle,
                onSelected: (_) => onToolChanged?.call(false),
              ),
              ChoiceChip(
                label: Text(s.rectangle),
                selected: rectangle,
                onSelected: (_) => onToolChanged?.call(true),
              ),
            ],
          ),
          const SizedBox(height: 8),
          preview(photo),
          const SizedBox(height: 10),
          Text(s.annotate, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          SizedBox(
            height: 74,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: photos.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, index) => Semantics(
                label: '${s.photos} ${index + 1}',
                selected: index == selected,
                button: true,
                child: MotionInkWell(
                  onTap: () => onSelect(index),
                  child: Container(
                    width: 80,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: index == selected
                            ? Colors.teal
                            : Colors.transparent,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: preview(photos[index], thumbnail: true),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            children: [
              if (photo.annotations.isNotEmpty)
                TextButton.icon(
                  onPressed: onUndo,
                  icon: const Icon(Icons.undo),
                  label: Text(s.undo),
                ),
              TextButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline),
                label: Text(s.deletePhoto),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
          ),
        ],
        OutlinedButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add_photo_alternate_outlined),
          label: Text(s.addPhotos),
        ),
        Text(
          s.photoSaveHint,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
