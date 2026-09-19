import '../../domain/entities/customer_order.dart';
import '../../domain/value_objects/order_status.dart';

class CustomerOrderModel extends CustomerOrder {
  const CustomerOrderModel({
    required super.id,
    required super.orderNumber,
    required super.clientId,
    required super.clientName,
    required super.clientPhone,
    required super.productType,
    super.description,
    required super.status,
    super.responsibleEmployeeId,
    super.responsibleEmployeeName,
    super.measurementDate,
    super.plannedCompletionDate,
    required super.totalAmountTiyn,
    required super.paidTiyn,
    required super.createdAt,
  });

  /// [paidTiyn] is computed separately by the datasource (a SUM over
  /// `payments`, see [CustomerOrder]'s doc comment) and merged in
  /// here — it is never a column on the `orders` row itself.
  factory CustomerOrderModel.fromRow(
    Map<String, dynamic> row, {
    required int paidTiyn,
  }) {
    final client = row['client'] as Map<String, dynamic>?;
    final employee = row['responsible_employee'] as Map<String, dynamic>?;

    return CustomerOrderModel(
      id: row['id'] as String,
      orderNumber: row['order_number'] as String,
      clientId: row['client_id'] as String,
      clientName: (client?['name'] as String?) ?? '',
      clientPhone: (client?['phone'] as String?) ?? '',
      productType: row['product_type'] as String,
      description: row['description'] as String?,
      status: OrderStatus.fromDbValue(row['status'] as String),
      responsibleEmployeeId: row['responsible_employee_id'] as String?,
      responsibleEmployeeName: employee?['full_name'] as String?,
      measurementDate: row['measurement_date'] != null
          ? DateTime.parse(row['measurement_date'] as String)
          : null,
      plannedCompletionDate: row['planned_completion_date'] != null
          ? DateTime.parse(row['planned_completion_date'] as String)
          : null,
      totalAmountTiyn: (row['total_amount_tiyn'] as num).toInt(),
      paidTiyn: paidTiyn,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }

  /// Insert/update payload — excludes `id`/`created_at`/`status`
  /// (status changes always go through
  /// [OrderRemoteDataSource.updateStatus] instead, even from the edit
  /// form, so there's exactly one code path that can trip the
  /// role-gated status trigger) and excludes `paid_tiyn` (not a real
  /// column at all — see [CustomerOrder]'s doc comment).
  Map<String, dynamic> toWriteMap() {
    return {
      'client_id': clientId,
      'product_type': productType,
      'description': description,
      'responsible_employee_id': responsibleEmployeeId,
      'measurement_date': measurementDate?.toIso8601String().substring(0, 10),
      'planned_completion_date': plannedCompletionDate
          ?.toIso8601String()
          .substring(0, 10),
      'total_amount_tiyn': totalAmountTiyn,
    };
  }
}
