import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/partner_document.dart';
import '../repositories/partner_repository.dart';

class GetPartnerDocumentsUseCase {
  const GetPartnerDocumentsUseCase(this._repository);
  final PartnerRepository _repository;

  Future<Either<Failure, List<PartnerDocument>>> call(String partnerId) {
    return _repository.getPartnerDocuments(partnerId);
  }
}
