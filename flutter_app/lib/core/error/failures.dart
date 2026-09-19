import 'package:flutter/foundation.dart';

import 'exceptions.dart';

/// Domain-layer error type returned by repositories via
/// `Either<Failure, T>` (fpdart) instead of throwing — keeps the
/// presentation layer from needing try/catch around every use case call.
@immutable
sealed class Failure {
  const Failure(this.message);

  /// Kazakh, user-facing message — never a raw exception string
  /// (per CLAUDE.md's Kazakh-first UI rule, this is what gets shown).
  final String message;
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Сервермен байланыс қатесі']);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Интернет байланысын тексеріңіз']);
}

class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

class PermissionFailure extends Failure {
  const PermissionFailure([super.message = 'Бұл әрекетке рұқсатыңыз жоқ']);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'Деректер табылмады']);
}

class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'Белгісіз қате орын алды']);
}

/// Maps to [BackendNotConfiguredException] — see that class for when
/// this is actually reachable (defense-in-depth only; app.dart's
/// backend-status branch is the real guard).
class ConfigurationFailure extends Failure {
  const ConfigurationFailure([
    super.message = 'Қолданба серверге қосылмаған. Әкімшіге хабарласыңыз',
  ]);
}

/// Repositories' catch-all clauses call this instead of hardcoding
/// [NetworkFailure] directly, so the one case that actually has a more
/// specific cause ([BackendNotConfiguredException] — see
/// core/providers/supabase_provider.dart) surfaces its own clearer
/// message rather than being reported as a generic connectivity issue.
Failure mapUnexpectedError(Object error) {
  if (error is BackendNotConfiguredException) {
    return const ConfigurationFailure();
  }
  return const NetworkFailure();
}
