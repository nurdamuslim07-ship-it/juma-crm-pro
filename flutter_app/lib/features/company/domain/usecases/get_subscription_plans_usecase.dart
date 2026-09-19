import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/subscription_plan.dart';
import '../repositories/company_repository.dart';

class GetSubscriptionPlansUseCase {
  const GetSubscriptionPlansUseCase(this._repository);
  final CompanyRepository _repository;

  Future<Either<Failure, List<SubscriptionPlan>>> call() {
    return _repository.getSubscriptionPlans();
  }
}
