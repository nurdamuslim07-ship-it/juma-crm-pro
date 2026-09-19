import '../../domain/entities/production_stage.dart';

class ProductionStageModel extends ProductionStage {
  const ProductionStageModel({
    required super.id,
    required super.key,
    required super.nameKk,
    required super.sortOrder,
    required super.defaultPercent,
  });

  factory ProductionStageModel.fromRow(Map<String, dynamic> row) {
    return ProductionStageModel(
      id: row['id'] as String,
      key: row['key'] as String,
      nameKk: (row['name_kk'] as String?) ?? '',
      sortOrder: (row['sort_order'] as num?)?.toInt() ?? 0,
      defaultPercent: (row['default_percent'] as num?)?.toInt() ?? 0,
    );
  }
}
