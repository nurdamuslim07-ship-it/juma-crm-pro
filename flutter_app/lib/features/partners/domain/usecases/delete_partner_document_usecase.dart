import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../repositories/partner_repository.dart';

class DeletePartnerDocumentUseCase {
  const DeletePartnerDocumentUseCase(this._repository);
  final PartnerRepository _repository;

  Future<Either<Failure, Unit>> call(String documentId) {
    return _repository.deletePartnerDocument(documentId);
  }
}
