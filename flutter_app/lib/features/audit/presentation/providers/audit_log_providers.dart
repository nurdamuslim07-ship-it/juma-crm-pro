import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/supabase_provider.dart';
import '../../data/datasources/audit_log_remote_datasource.dart';
import '../../data/repositories/audit_log_repository_impl.dart';
import '../../domain/entities/audit_log_filters.dart';
import '../../domain/entities/audit_log_page.dart';
import '../../domain/entities/audit_log_query.dart';
import '../../domain/repositories/audit_log_repository.dart';
import '../../domain/usecases/get_audit_log_filters_usecase.dart';
import '../../domain/usecases/get_audit_logs_usecase.dart';

final auditLogRemoteDataSourceProvider = Provider<AuditLogRemoteDataSource>((
  ref,
) {
  return AuditLogRemoteDataSource(ref.watch(supabaseClientProvider));
});

final auditLogRepositoryProvider = Provider<AuditLogRepository>((ref) {
  return AuditLogRepositoryImpl(ref.watch(auditLogRemoteDataSourceProvider));
});

final getAuditLogsUseCaseProvider = Provider<GetAuditLogsUseCase>((ref) {
  return GetAuditLogsUseCase(ref.watch(auditLogRepositoryProvider));
});

final getAuditLogFiltersUseCaseProvider = Provider<GetAuditLogFiltersUseCase>((
  ref,
) {
  return GetAuditLogFiltersUseCase(ref.watch(auditLogRepositoryProvider));
});

/// Holds the current filter/pagination state — screen widgets mutate
/// this (via `.copyWith`) instead of juggling 7 separate `StateProvider`s.
final auditLogQueryProvider = StateProvider.autoDispose<AuditLogQuery>(
  (ref) => const AuditLogQuery(),
);

final auditLogsProvider = FutureProvider.autoDispose<AuditLogPage>((ref) {
  final query = ref.watch(auditLogQueryProvider);
  return ref
      .watch(getAuditLogsUseCaseProvider)
      .call(query)
      .then(
        (either) => either.match((failure) => throw failure, (data) => data),
      );
});

final auditLogFiltersProvider = FutureProvider.autoDispose<AuditLogFilters>((
  ref,
) {
  return ref
      .watch(getAuditLogFiltersUseCaseProvider)
      .call()
      .then(
        (either) => either.match((failure) => throw failure, (data) => data),
      );
});
