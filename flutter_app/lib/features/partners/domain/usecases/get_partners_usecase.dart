import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/partner.dart';
import '../repositories/partner_repository.dart';
import '../value_objects/partner_category.dart';

class GetPartnersUseCase {
  const GetPartnersUseCase(this._repository);
  final PartnerRepository _repository;

  Future<Either<Failure, List<Partner>>> call({
    String? searchQuery,
    PartnerCategory? categoryFilter,
    bool? activeFilter,
    bool includeDeleted = false,
    int limit = 50,
    int offset = 0,
  }) {
    return _repository.getPartners(
      searchQuery: searchQuery,
      categoryFilter: categoryFilter,
      activeFilter: activeFilter,
      includeDeleted: includeDeleted,
      limit: limit,
      offset: offset,
    );
  }
}
