import 'package:flutter/foundation.dart';

import '../value_objects/company_role.dart';
import '../value_objects/join_request_status.dart';

/// The requester's own view of a join request — backs
/// `get_my_join_requests()` / the Waiting Approval screen. See
/// supabase/migrations/20260713000036_company_registration_module.sql.
@immutable
class CompanyJoinRequest {
  const CompanyJoinRequest({
    required this.id,
    required this.companyId,
    required this.companyName,
    required this.requestedRole,
    this.message,
    required this.status,
    this.rejectionReason,
    required this.createdAt,
    this.reviewedAt,
  });

  final String id;
  final String companyId;
  final String companyName;
  final CompanyRole requestedRole;
  final String? message;
  final JoinRequestStatus status;
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime? reviewedAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CompanyJoinRequest &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          status == other.status;

  @override
  int get hashCode => Object.hash(id, status);
}
