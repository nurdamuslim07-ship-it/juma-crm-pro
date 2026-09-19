import 'package:flutter/foundation.dart';

/// A freshly-created invite code — backs `create_company_invitation()`'s
/// return value, shown to the director as text + QR (reusing
/// `qr_flutter`, already a dependency — see InviteEmployeeScreen).
@immutable
class CompanyInvitation {
  const CompanyInvitation({required this.code, required this.expiresAt});

  final String code;
  final DateTime expiresAt;
}
