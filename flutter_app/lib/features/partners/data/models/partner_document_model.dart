import '../../domain/entities/partner_document.dart';

class PartnerDocumentModel extends PartnerDocument {
  const PartnerDocumentModel({
    required super.id,
    required super.partnerId,
    required super.storagePath,
    required super.fileName,
    super.uploadedBy,
    required super.createdAt,
  });

  factory PartnerDocumentModel.fromRow(Map<String, dynamic> row) {
    return PartnerDocumentModel(
      id: row['id'] as String,
      partnerId: row['partner_id'] as String,
      storagePath: row['storage_path'] as String,
      fileName: (row['file_name'] as String?) ?? '',
      uploadedBy: row['uploaded_by'] as String?,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }
}
