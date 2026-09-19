import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../repositories/company_repository.dart';

class UpdateCompanySettingsUseCase {
  const UpdateCompanySettingsUseCase(this._repository);
  final CompanyRepository _repository;

  Future<Either<Failure, Unit>> call({
    required String name,
    String? logo,
    String? phone,
    String? email,
    String? address,
    String? iinBin,
    String? website,
    String? timezone,
    String? currency,
    String? workingHours,
    String? description,
  }) {
    return _repository.updateCompanySettings(
      name: name,
      logo: logo,
      phone: phone,
      email: email,
      address: address,
      iinBin: iinBin,
      website: website,
      timezone: timezone,
      currency: currency,
      workingHours: workingHours,
      description: description,
    );
  }
}
