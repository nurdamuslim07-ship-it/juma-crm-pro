import '../../domain/entities/auth_user.dart';
import '../../domain/entities/profile_status.dart';

/// Data-layer DTO — maps a Supabase `profiles` row (joined with
/// `user_roles`/`roles`, and optionally the owning `companies` row) into
/// the domain [AuthUser] entity. Kept as a thin factory rather than a
/// full separate class hierarchy since the shape is simple; see
/// DATABASE_SCHEMA.md for the `profiles` table this reads from.
class AuthUserModel extends AuthUser {
  const AuthUserModel({
    required super.id,
    required super.fullName,
    super.email,
    super.phone,
    super.avatarUrl,
    required super.isActive,
    required super.roleKeys,
    super.companyId,
    super.status,
    super.companyIsActive,
    super.emailConfirmedAt,
    super.phoneConfirmedAt,
  });

  factory AuthUserModel.fromProfileRow(
    Map<String, dynamic> row, {
    required List<String> roleKeys,
    String? email,
    String? emailConfirmedAt,
    String? phoneConfirmedAt,
  }) {
    final statusKey = row['status'] as String?;
    final company = row['companies'] as Map<String, dynamic>?;
    return AuthUserModel(
      id: row['id'] as String,
      fullName: (row['full_name'] as String?) ?? '',
      email: email,
      phone: row['phone'] as String?,
      avatarUrl: row['avatar_url'] as String?,
      isActive: (row['is_active'] as bool?) ?? true,
      roleKeys: roleKeys,
      companyId: row['company_id'] as String?,
      status: statusKey == null ? null : ProfileStatus.fromDbKey(statusKey),
      companyIsActive: (company?['is_active'] as bool?) ?? true,
      emailConfirmedAt: emailConfirmedAt == null
          ? null
          : DateTime.tryParse(emailConfirmedAt),
      phoneConfirmedAt: phoneConfirmedAt == null
          ? null
          : DateTime.tryParse(phoneConfirmedAt),
    );
  }
}
