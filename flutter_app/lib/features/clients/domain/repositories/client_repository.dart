import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/client.dart';

abstract class ClientRepository {
  Future<Either<Failure, List<Client>>> getClients({String? searchQuery});
  Future<Either<Failure, Client>> getClient(String id);
  Future<Either<Failure, Client>> createClient(
    Client client, {
    required String companyId,
  });
  Future<Either<Failure, Client>> updateClient(Client client);
  Future<Either<Failure, Unit>> deleteClient(String id);
}
