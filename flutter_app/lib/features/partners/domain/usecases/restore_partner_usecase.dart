import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../repositories/partner_repository.dart';

class RestorePartnerUseCase {
  const RestorePartnerUseCase(this._repository);
  final PartnerRepository _repository;

  Future<Either<Failure, Unit>> call(String id) {
    return _repository.restorePartner(id);
  }
}
