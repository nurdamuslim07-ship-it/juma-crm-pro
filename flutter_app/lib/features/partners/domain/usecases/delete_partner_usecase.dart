import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../repositories/partner_repository.dart';

class DeletePartnerUseCase {
  const DeletePartnerUseCase(this._repository);
  final PartnerRepository _repository;

  Future<Either<Failure, Unit>> call(String id) {
    return _repository.deletePartner(id);
  }
}
