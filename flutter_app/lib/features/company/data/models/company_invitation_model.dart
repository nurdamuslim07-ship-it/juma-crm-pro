import '../../domain/entities/company_invitation.dart';

class CompanyInvitationModel extends CompanyInvitation {
  const CompanyInvitationModel({required super.code, required super.expiresAt});

  /// Parses `create_company_invitation()`'s single-row result set.
  factory CompanyInvitationModel.fromRow(Map<String, dynamic> row) {
    return CompanyInvitationModel(
      code: row['code'] as String,
      expiresAt: DateTime.parse(row['expires_at'] as String),
    );
  }
}
