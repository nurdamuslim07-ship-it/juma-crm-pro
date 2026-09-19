import '../../domain/entities/production_photo.dart';

class ProductionPhotoModel extends ProductionPhoto {
  const ProductionPhotoModel({
    required super.id,
    required super.storagePath,
    required super.uploadedAt,
  });

  factory ProductionPhotoModel.fromRow(Map<String, dynamic> row) {
    return ProductionPhotoModel(
      id: row['id'] as String,
      storagePath: row['storage_path'] as String,
      uploadedAt: DateTime.parse(row['uploaded_at'] as String),
    );
  }
}
