import '../../domain/entities/material_category.dart';

class MaterialCategoryModel extends MaterialCategory {
  const MaterialCategoryModel({
    required super.id,
    required super.key,
    required super.nameKk,
  });

  factory MaterialCategoryModel.fromRow(Map<String, dynamic> row) {
    return MaterialCategoryModel(
      id: row['id'] as String,
      key: row['key'] as String,
      nameKk: (row['name_kk'] as String?) ?? '',
    );
  }
}
