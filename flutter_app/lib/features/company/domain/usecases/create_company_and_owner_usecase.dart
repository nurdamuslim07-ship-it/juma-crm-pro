import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../repositories/company_repository.dart';

class CreateCompanyAndOwnerUseCase {
  const CreateCompanyAndOwnerUseCase(this._repository);
  final CompanyRepository _repository;

  Future<Either<Failure, String>> call({
    required String name,
    String? phone,
    String? email,
    String? city,
    String? address,
    String? iinBin,
  }) {
    return _repository.createCompanyAndOwner(
      name: name,
      phone: phone,
      email: email,
      city: city,
      address: address,
      iinBin: iinBin,
    );
  }
}
