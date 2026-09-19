import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/client.dart';
import '../repositories/client_repository.dart';

/// Handles both create and update — the form (see
/// ClientFormSheet) decides which by whether the client already has
/// a persisted id, matching the master spec's single "Жаңа клиент /
/// Клиентті өңдеу" flow rather than two separate screens.
class UpsertClientUseCase {
  const UpsertClientUseCase(this._repository);
  final ClientRepository _repository;

  /// `companyId` is only consulted when [isNew] — required then
  /// (never null, never a caller-supplied literal; see
  /// ClientFormSheet, which resolves it from the authenticated user's
  /// own active company and refuses to call this at all if that is
  /// unavailable).
  Future<Either<Failure, Client>> call(
    Client client, {
    required bool isNew,
    String? companyId,
  }) {
    if (isNew) {
      assert(companyId != null, 'companyId is required when isNew is true');
      return _repository.createClient(client, companyId: companyId!);
    }
    return _repository.updateClient(client);
  }
}
