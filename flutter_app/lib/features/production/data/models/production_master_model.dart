import '../../domain/entities/production_master.dart';

class ProductionMasterModel extends ProductionMaster {
  const ProductionMasterModel({required super.userId, required super.fullName});

  factory ProductionMasterModel.fromRow(Map<String, dynamic> row) {
    return ProductionMasterModel(
      userId: row['user_id'] as String,
      fullName: (row['full_name'] as String?) ?? '',
    );
  }
}
