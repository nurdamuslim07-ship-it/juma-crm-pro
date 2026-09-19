import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/company_subscription_info.dart';
import '../repositories/company_repository.dart';

class GetSubscriptionInfoUseCase {
  const GetSubscriptionInfoUseCase(this._repository);
  final CompanyRepository _repository;

  Future<Either<Failure, CompanySubscriptionInfo>> call() {
    return _repository.getSubscriptionInfo();
  }
}
