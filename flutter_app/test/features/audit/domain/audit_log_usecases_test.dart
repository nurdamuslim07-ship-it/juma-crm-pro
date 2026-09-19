import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:juma_ui_crm/core/error/failures.dart';
import 'package:juma_ui_crm/features/audit/domain/entities/audit_log_entry.dart';
import 'package:juma_ui_crm/features/audit/domain/entities/audit_log_filters.dart';
import 'package:juma_ui_crm/features/audit/domain/entities/audit_log_page.dart';
import 'package:juma_ui_crm/features/audit/domain/entities/audit_log_query.dart';
import 'package:juma_ui_crm/features/audit/domain/repositories/audit_log_repository.dart';
import 'package:juma_ui_crm/features/audit/domain/usecases/get_audit_log_filters_usecase.dart';
import 'package:juma_ui_crm/features/audit/domain/usecases/get_audit_logs_usecase.dart';

/// Hand-written fake — same approach as every other repository test in
/// this codebase (no mocking framework exists).
class _FakeAuditLogRepository implements AuditLogRepository {
  Failure? failureToReturn;
  AuditLogQuery? lastQuery;

  @override
  Future<Either<Failure, AuditLogPage>> getAuditLogs(
    AuditLogQuery query,
  ) async {
    lastQuery = query;
    if (failureToReturn != null) return left(failureToReturn!);
    return right(
      AuditLogPage(
        entries: [
          AuditLogEntry(
            id: 'log-1',
            action: 'company_created',
            entityType: 'companies',
            createdAt: DateTime(2026, 7, 1),
          ),
        ],
        totalCount: 1,
      ),
    );
  }

  @override
  Future<Either<Failure, AuditLogFilters>> getFilters() async {
    if (failureToReturn != null) return left(failureToReturn!);
    return right(
      const AuditLogFilters(
        modules: ['companies', 'company_join_requests'],
        actions: ['company_created', 'join_request_approved'],
      ),
    );
  }
}

void main() {
  late _FakeAuditLogRepository repository;

  setUp(() {
    repository = _FakeAuditLogRepository();
  });

  group('GetAuditLogsUseCase', () {
    test('passes the query through unchanged', () async {
      final useCase = GetAuditLogsUseCase(repository);
      const query = AuditLogQuery(actorId: 'user-1', offset: 20);
      await useCase(query);
      expect(repository.lastQuery, query);
    });

    test('returns a page with entries and totalCount', () async {
      final useCase = GetAuditLogsUseCase(repository);
      final result = await useCase(const AuditLogQuery());
      result.match((_) => fail('expected right'), (page) {
        expect(page.entries, hasLength(1));
        expect(page.totalCount, 1);
      });
    });

    test(
      'a non-director caller surfaces as PermissionFailure (RLS denies the select)',
      () async {
        repository.failureToReturn = const PermissionFailure();
        final useCase = GetAuditLogsUseCase(repository);
        final result = await useCase(const AuditLogQuery());
        result.match(
          (failure) => expect(failure, isA<PermissionFailure>()),
          (_) => fail('expected left'),
        );
      },
    );
  });

  group('GetAuditLogFiltersUseCase', () {
    test('returns the modules/actions dropdown options', () async {
      final useCase = GetAuditLogFiltersUseCase(repository);
      final result = await useCase();
      result.match((_) => fail('expected right'), (filters) {
        expect(filters.modules, contains('companies'));
        expect(filters.actions, contains('company_created'));
      });
    });
  });
}
