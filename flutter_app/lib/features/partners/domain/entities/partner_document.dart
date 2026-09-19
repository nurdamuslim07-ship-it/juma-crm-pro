import 'package:flutter/foundation.dart';

/// A price list/contract/document attached to a partner (requirement
/// #13 "Прайс немесе құжат тіркеу"). Metadata only — the file bytes
/// live in the private `partner-documents` Storage bucket, fetched via
/// a signed URL (see PartnerRepository.getDocumentSignedUrl).
@immutable
class PartnerDocument {
  const PartnerDocument({
    required this.id,
    required this.partnerId,
    required this.storagePath,
    required this.fileName,
    this.uploadedBy,
    required this.createdAt,
  });

  final String id;
  final String partnerId;
  final String storagePath;
  final String fileName;
  final String? uploadedBy;
  final DateTime createdAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PartnerDocument &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
