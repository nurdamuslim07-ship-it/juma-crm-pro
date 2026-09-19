import '../../domain/entities/client.dart';

class ClientModel extends Client {
  const ClientModel({
    required super.id,
    required super.name,
    required super.phone,
    super.phoneSecondary,
    super.whatsappOrTelegram,
    super.address,
    super.city,
    super.source,
    super.responsibleManagerId,
    super.responsibleManagerName,
    super.preferredLanguage,
    super.notes,
    required super.createdAt,
  });

  factory ClientModel.fromRow(Map<String, dynamic> row) {
    final managerRow = row['responsible_manager'] as Map<String, dynamic>?;
    return ClientModel(
      id: row['id'] as String,
      name: row['name'] as String,
      phone: row['phone'] as String,
      phoneSecondary: row['phone_secondary'] as String?,
      whatsappOrTelegram: row['whatsapp_or_telegram'] as String?,
      address: row['address'] as String?,
      city: row['city'] as String?,
      source: row['source'] as String?,
      responsibleManagerId: row['responsible_manager_id'] as String?,
      responsibleManagerName: managerRow?['full_name'] as String?,
      preferredLanguage: (row['preferred_language'] as String?) ?? 'kk',
      notes: row['notes'] as String?,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }

  /// Insert/update payload — deliberately excludes `id`/`created_at`
  /// (server-assigned) and `deleted_at` (only ever set by the soft
  /// delete path, see [ClientRemoteDataSource.deleteClient]).
  Map<String, dynamic> toWriteMap() {
    return {
      'name': name,
      'phone': phone,
      'phone_secondary': phoneSecondary,
      'whatsapp_or_telegram': whatsappOrTelegram,
      'address': address,
      'city': city,
      'source': source,
      'responsible_manager_id': responsibleManagerId,
      'preferred_language': preferredLanguage,
      'notes': notes,
    };
  }
}
