import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../repositories/client_repository.dart';

class DeleteClientUseCase {
  const DeleteClientUseCase(this._repository);
  final ClientRepository _repository;

  Future<Either<Failure, Unit>> call(String id) => _repository.deleteClient(id);
}
