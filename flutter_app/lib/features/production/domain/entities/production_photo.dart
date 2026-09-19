import 'package:flutter/foundation.dart';

/// A photo attached to an order's production progress (requirement #2
/// "Фото тіркеу") — backed by the existing `order_photos` table
/// (`kind = 'production'`), not a new table.
@immutable
class ProductionPhoto {
  const ProductionPhoto({
    required this.id,
    required this.storagePath,
    required this.uploadedAt,
  });

  final String id;
  final String storagePath;
  final DateTime uploadedAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductionPhoto &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
