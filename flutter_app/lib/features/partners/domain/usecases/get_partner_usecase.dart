import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/partner.dart';
import '../repositories/partner_repository.dart';

class GetPartnerUseCase {
  const GetPartnerUseCase(this._repository);
  final PartnerRepository _repository;

  Future<Either<Failure, Partner>> call(String id) {
    return _repository.getPartner(id);
  }
}
