import '../../domain/entities/top_client.dart';

class TopClientModel extends TopClient {
  const TopClientModel({
    required super.clientId,
    required super.clientName,
    required super.ordersCount,
    required super.totalAmountTiyn,
  });

  factory TopClientModel.fromRow(Map<String, dynamic> row) {
    return TopClientModel(
      clientId: row['client_id'] as String,
      clientName: (row['client_name'] as String?) ?? '',
      ordersCount: (row['orders_count'] as num?)?.toInt() ?? 0,
      totalAmountTiyn: (row['total_amount_tiyn'] as num?)?.toInt() ?? 0,
    );
  }
}
