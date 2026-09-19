import 'package:flutter/foundation.dart';

/// The editable "settings" slice of a `companies` row — deliberately
/// excludes `subscription_plan`/`subscription_status`/
/// `subscription_expires_at`/`is_active`/`code`, which are lifecycle
/// fields, not settings (see `update_company_settings()`'s own header
/// comment in
/// supabase/migrations/20260713000038_company_settings_subscription.sql).
@immutable
class CompanySettings {
  const CompanySettings({
    required this.id,
    required this.name,
    this.logo,
    this.phone,
    this.email,
    this.address,
    this.iinBin,
    this.website,
    required this.timezone,
    required this.currency,
    this.workingHours,
    this.description,
  });

  final String id;
  final String name;
  final String? logo;
  final String? phone;
  final String? email;
  final String? address;
  final String? iinBin;
  final String? website;
  final String timezone;
  final String currency;
  final String? workingHours;
  final String? description;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CompanySettings &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          logo == other.logo &&
          phone == other.phone &&
          email == other.email &&
          address == other.address &&
          iinBin == other.iinBin &&
          website == other.website &&
          timezone == other.timezone &&
          currency == other.currency &&
          workingHours == other.workingHours &&
          description == other.description;

  @override
  int get hashCode => Object.hash(
    id,
    name,
    logo,
    phone,
    email,
    address,
    iinBin,
    website,
    timezone,
    currency,
    workingHours,
    description,
  );
}
