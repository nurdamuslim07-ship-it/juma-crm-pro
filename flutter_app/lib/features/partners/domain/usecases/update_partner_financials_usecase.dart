import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../repositories/partner_repository.dart';

class UpdatePartnerFinancialsUseCase {
  const UpdatePartnerFinancialsUseCase(this._repository);
  final PartnerRepository _repository;

  Future<Either<Failure, Unit>> call({
    required String id,
    String? bankDetails,
    required int balanceTiyn,
  }) {
    return _repository.updatePartnerFinancials(
      id: id,
      bankDetails: bankDetails,
      balanceTiyn: balanceTiyn,
    );
  }
}
