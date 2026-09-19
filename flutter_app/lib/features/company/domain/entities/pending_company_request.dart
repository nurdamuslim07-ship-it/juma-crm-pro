import 'package:flutter/foundation.dart';

import '../value_objects/company_role.dart';

/// A director/owner's own view of ONE incoming request — backs
/// `get_pending_company_requests()`. Always scoped to the caller's own
/// company server-side (get_pending_company_requests() filters by
/// `auth_company_id()`); this entity never carries a company id
/// because there is never a choice of which company to look at.
@immutable
class PendingCompanyRequest {
  const PendingCompanyRequest({
    required this.id,
    required this.profileId,
    required this.fullName,
    this.phone,
    required this.requestedRole,
    this.message,
    required this.createdAt,
  });

  final String id;
  final String profileId;
  final String fullName;
  final String? phone;
  final CompanyRole requestedRole;
  final String? message;
  final DateTime createdAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PendingCompanyRequest &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
