import '../../domain/entities/audit_log_entry.dart';

class AuditLogEntryModel extends AuditLogEntry {
  const AuditLogEntryModel({
    required super.id,
    super.actorId,
    super.actorName,
    required super.action,
    required super.entityType,
    super.entityId,
    super.before,
    super.after,
    required super.createdAt,
  });

  /// Parses a row from `.from('audit_logs').select('*, profiles(full_name)')`.
  factory AuditLogEntryModel.fromRow(Map<String, dynamic> row) {
    final actor = row['profiles'] as Map<String, dynamic>?;
    return AuditLogEntryModel(
      id: row['id'] as String,
      actorId: row['actor_id'] as String?,
      actorName: actor?['full_name'] as String?,
      action: row['action'] as String,
      entityType: row['entity_type'] as String,
      entityId: row['entity_id'] as String?,
      before: row['before'] as Map<String, dynamic>?,
      after: row['after'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }
}
