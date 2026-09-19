import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/company_settings.dart';
import '../repositories/company_repository.dart';

class GetCompanySettingsUseCase {
  const GetCompanySettingsUseCase(this._repository);
  final CompanyRepository _repository;

  Future<Either<Failure, CompanySettings>> call() {
    return _repository.getCompanySettings();
  }
}
