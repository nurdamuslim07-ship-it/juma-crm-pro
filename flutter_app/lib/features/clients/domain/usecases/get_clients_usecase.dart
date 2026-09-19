import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/client.dart';
import '../repositories/client_repository.dart';

class GetClientsUseCase {
  const GetClientsUseCase(this._repository);
  final ClientRepository _repository;

  Future<Either<Failure, List<Client>>> call({String? searchQuery}) {
    return _repository.getClients(searchQuery: searchQuery);
  }
}
