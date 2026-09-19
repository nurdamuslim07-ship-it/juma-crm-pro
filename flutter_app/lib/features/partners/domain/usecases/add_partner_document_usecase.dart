import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/partner_document.dart';
import '../repositories/partner_repository.dart';

class AddPartnerDocumentUseCase {
  const AddPartnerDocumentUseCase(this._repository);
  final PartnerRepository _repository;

  Future<Either<Failure, PartnerDocument>> call({
    required String partnerId,
    required List<int> bytes,
    required String fileName,
  }) {
    return _repository.addPartnerDocument(
      partnerId: partnerId,
      bytes: bytes,
      fileName: fileName,
    );
  }
}
