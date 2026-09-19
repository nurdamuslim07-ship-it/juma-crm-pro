import 'package:flutter/foundation.dart';

/// See DATABASE_SCHEMA.md "Clients & measurements" — extends the
/// legacy web app's flat Client shape (name/phone/address/totalOrders/
/// totalSpent only) with the fields REQUIREMENTS.md flagged as
/// missing: secondary phone, WhatsApp/Telegram contact, source,
/// responsible manager, preferred language.
@immutable
class Client {
  const Client({
    required this.id,
    required this.name,
    required this.phone,
    this.phoneSecondary,
    this.whatsappOrTelegram,
    this.address,
    this.city,
    this.source,
    this.responsibleManagerId,
    this.responsibleManagerName,
    this.preferredLanguage = 'kk',
    this.notes,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String phone;
  final String? phoneSecondary;
  final String? whatsappOrTelegram;
  final String? address;
  final String? city;
  final String? source;
  final String? responsibleManagerId;
  final String? responsibleManagerName;
  final String preferredLanguage;
  final String? notes;
  final DateTime createdAt;

  Client copyWith({
    String? name,
    String? phone,
    String? phoneSecondary,
    String? whatsappOrTelegram,
    String? address,
    String? city,
    String? source,
    String? responsibleManagerId,
    String? notes,
  }) {
    return Client(
      id: id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      phoneSecondary: phoneSecondary ?? this.phoneSecondary,
      whatsappOrTelegram: whatsappOrTelegram ?? this.whatsappOrTelegram,
      address: address ?? this.address,
      city: city ?? this.city,
      source: source ?? this.source,
      responsibleManagerId: responsibleManagerId ?? this.responsibleManagerId,
      responsibleManagerName: responsibleManagerName,
      preferredLanguage: preferredLanguage,
      notes: notes ?? this.notes,
      createdAt: createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Client && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
