import '../../domain/entities/pending_company_request.dart';
import '../../domain/value_objects/company_role.dart';

class PendingCompanyRequestModel extends PendingCompanyRequest {
  const PendingCompanyRequestModel({
    required super.id,
    required super.profileId,
    required super.fullName,
    super.phone,
    required super.requestedRole,
    super.message,
    required super.createdAt,
  });

  /// Parses one row of `get_pending_company_requests()`'s result set.
  factory PendingCompanyRequestModel.fromRow(Map<String, dynamic> row) {
    return PendingCompanyRequestModel(
      id: row['id'] as String,
      profileId: row['profile_id'] as String,
      fullName: (row['full_name'] as String?) ?? '',
      phone: row['phone'] as String?,
      requestedRole: CompanyRole.fromDbKey(row['requested_role'] as String),
      message: row['message'] as String?,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }
}
