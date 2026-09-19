/// Data-layer exceptions thrown by datasources, caught and translated
/// into [Failure]s by repository implementations — the domain/presentation
/// layers never see these directly.
class ServerException implements Exception {
  const ServerException([this.message]);
  final String? message;
}

class AuthException implements Exception {
  const AuthException(this.message);
  final String message;
}

class NetworkException implements Exception {
  const NetworkException([this.message]);
  final String? message;
}

class NotFoundException implements Exception {
  const NotFoundException([this.message]);
  final String? message;
}

/// Thrown by [supabaseClientProvider] if something ever reads it
/// before `Supabase.initialize()` completed. Under normal operation
/// this should be unreachable — `app.dart` never builds the
/// provider/router tree unless `backendStatusProvider` is
/// `BackendStatus.ready` — this exists as a defense-in-depth guard so
/// that if it *is* ever reached, the failure is a clear, typed
/// exception instead of the raw `Supabase.instance` assertion error.
class BackendNotConfiguredException implements Exception {
  const BackendNotConfiguredException();
}
