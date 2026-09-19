import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/supabase_provider.dart';
import '../../data/datasources/client_remote_datasource.dart';
import '../../data/repositories/client_repository_impl.dart';
import '../../domain/entities/client.dart';
import '../../domain/repositories/client_repository.dart';
import '../../domain/usecases/delete_client_usecase.dart';
import '../../domain/usecases/get_clients_usecase.dart';
import '../../domain/usecases/upsert_client_usecase.dart';

final clientRemoteDataSourceProvider = Provider<ClientRemoteDataSource>((ref) {
  return ClientRemoteDataSource(ref.watch(supabaseClientProvider));
});

final clientRepositoryProvider = Provider<ClientRepository>((ref) {
  return ClientRepositoryImpl(ref.watch(clientRemoteDataSourceProvider));
});

final getClientsUseCaseProvider = Provider<GetClientsUseCase>((ref) {
  return GetClientsUseCase(ref.watch(clientRepositoryProvider));
});

final upsertClientUseCaseProvider = Provider<UpsertClientUseCase>((ref) {
  return UpsertClientUseCase(ref.watch(clientRepositoryProvider));
});

final deleteClientUseCaseProvider = Provider<DeleteClientUseCase>((ref) {
  return DeleteClientUseCase(ref.watch(clientRepositoryProvider));
});

/// Live search-box text — the list provider watches this and refetches
/// (debounced in the UI layer, see ClientsListScreen).
final clientSearchQueryProvider = StateProvider<String>((ref) => '');

final clientsListProvider = FutureProvider.autoDispose<List<Client>>((ref) {
  final query = ref.watch(clientSearchQueryProvider);
  return ref
      .watch(getClientsUseCaseProvider)
      .call(searchQuery: query)
      .then(
        (either) => either.match((failure) => throw failure, (data) => data),
      );
});

final clientDetailProvider = FutureProvider.autoDispose.family<Client, String>((
  ref,
  id,
) {
  return ref
      .watch(clientRepositoryProvider)
      .getClient(id)
      .then(
        (either) => either.match((failure) => throw failure, (data) => data),
      );
});
