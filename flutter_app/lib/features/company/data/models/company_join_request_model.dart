import '../../domain/entities/company_join_request.dart';
import '../../domain/value_objects/company_role.dart';
import '../../domain/value_objects/join_request_status.dart';

class CompanyJoinRequestModel extends CompanyJoinRequest {
  const CompanyJoinRequestModel({
    required super.id,
    required super.companyId,
    required super.companyName,
    required super.requestedRole,
    super.message,
    required super.status,
    super.rejectionReason,
    required super.createdAt,
    super.reviewedAt,
  });

  /// Parses one row of `get_my_join_requests()`'s result set.
  factory CompanyJoinRequestModel.fromRow(Map<String, dynamic> row) {
    return CompanyJoinRequestModel(
      id: row['id'] as String,
      companyId: row['company_id'] as String,
      companyName: (row['company_name'] as String?) ?? '',
      requestedRole: CompanyRole.fromDbKey(row['requested_role'] as String),
      message: row['message'] as String?,
      status: JoinRequestStatus.fromDbKey(row['status'] as String),
      rejectionReason: row['rejection_reason'] as String?,
      createdAt: DateTime.parse(row['created_at'] as String),
      reviewedAt: row['reviewed_at'] != null
          ? DateTime.parse(row['reviewed_at'] as String)
          : null,
    );
  }
}
