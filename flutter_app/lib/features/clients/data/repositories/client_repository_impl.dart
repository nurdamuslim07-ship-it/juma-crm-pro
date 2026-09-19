import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../../../core/error/failures.dart';
import '../../domain/entities/client.dart';
import '../../domain/repositories/client_repository.dart';
import '../datasources/client_remote_datasource.dart';
import '../models/client_model.dart';

class ClientRepositoryImpl implements ClientRepository {
  ClientRepositoryImpl(this._remote);
  final ClientRemoteDataSource _remote;

  @override
  Future<Either<Failure, List<Client>>> getClients({
    String? searchQuery,
  }) async {
    try {
      final clients = await _remote.getClients(searchQuery: searchQuery);
      return right(clients);
    } on PostgrestException catch (e) {
      return left(_mapPostgrestError(e));
    } catch (e) {
      return left(mapUnexpectedError(e));
    }
  }

  @override
  Future<Either<Failure, Client>> getClient(String id) async {
    try {
      final client = await _remote.getClient(id);
      return right(client);
    } on PostgrestException catch (e) {
      return left(_mapPostgrestError(e));
    } catch (e) {
      return left(mapUnexpectedError(e));
    }
  }

  @override
  Future<Either<Failure, Client>> createClient(
    Client client, {
    required String companyId,
  }) async {
    try {
      final created = await _remote.createClient(
        _toModel(client),
        companyId: companyId,
      );
      return right(created);
    } on PostgrestException catch (e) {
      return left(_mapPostgrestError(e));
    } catch (e) {
      return left(mapUnexpectedError(e));
    }
  }

  @override
  Future<Either<Failure, Client>> updateClient(Client client) async {
    try {
      final updated = await _remote.updateClient(_toModel(client));
      return right(updated);
    } on PostgrestException catch (e) {
      return left(_mapPostgrestError(e));
    } catch (e) {
      return left(mapUnexpectedError(e));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteClient(String id) async {
    try {
      await _remote.deleteClient(id);
      return right(unit);
    } on PostgrestException catch (e) {
      return left(_mapPostgrestError(e));
    } catch (e) {
      return left(mapUnexpectedError(e));
    }
  }

  ClientModel _toModel(Client client) => ClientModel(
    id: client.id,
    name: client.name,
    phone: client.phone,
    phoneSecondary: client.phoneSecondary,
    whatsappOrTelegram: client.whatsappOrTelegram,
    address: client.address,
    city: client.city,
    source: client.source,
    responsibleManagerId: client.responsibleManagerId,
    preferredLanguage: client.preferredLanguage,
    notes: client.notes,
    createdAt: client.createdAt,
  );

  Failure _mapPostgrestError(PostgrestException e) {
    if (e.code == '42501') return const PermissionFailure();
    if (e.code == 'PGRST116') return const NotFoundFailure();
    return ServerFailure(e.message);
  }
}
