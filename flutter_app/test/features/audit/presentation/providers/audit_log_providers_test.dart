import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:juma_ui_crm/core/error/failures.dart';
import 'package:juma_ui_crm/features/audit/domain/entities/audit_log_entry.dart';
import 'package:juma_ui_crm/features/audit/domain/entities/audit_log_filters.dart';
import 'package:juma_ui_crm/features/audit/domain/entities/audit_log_page.dart';
import 'package:juma_ui_crm/features/audit/domain/entities/audit_log_query.dart';
import 'package:juma_ui_crm/features/audit/domain/repositories/audit_log_repository.dart';
import 'package:juma_ui_crm/features/audit/presentation/providers/audit_log_providers.dart';

class _FakeAuditLogRepository implements AuditLogRepository {
  AuditLogQuery? lastQuery;

  @override
  Future<Either<Failure, AuditLogPage>> getAuditLogs(
    AuditLogQuery query,
  ) async {
    lastQuery = query;
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
    return right(
      const AuditLogFilters(
        modules: ['companies'],
        actions: ['company_created'],
      ),
    );
  }
}

void main() {
  late _FakeAuditLogRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = _FakeAuditLogRepository();
    container = ProviderContainer(
      overrides: [auditLogRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
  });

  test('auditLogQueryProvider starts with no filters and offset 0', () {
    final query = container.read(auditLogQueryProvider);
    expect(query.actorId, isNull);
    expect(query.offset, 0);
  });

  test(
    'auditLogsProvider resolves using the current auditLogQueryProvider state',
    () async {
      container.read(auditLogQueryProvider.notifier).state =
          const AuditLogQuery(actorId: 'user-1');

      final page = await container.read(auditLogsProvider.future);

      expect(repository.lastQuery?.actorId, 'user-1');
      expect(page.entries, hasLength(1));
      expect(page.totalCount, 1);
    },
  );

  test(
    'changing auditLogQueryProvider triggers a refetch with the new query',
    () async {
      await container.read(auditLogsProvider.future);
      container.read(auditLogQueryProvider.notifier).state =
          const AuditLogQuery(offset: 20);
      await container.read(auditLogsProvider.future);

      expect(repository.lastQuery?.offset, 20);
    },
  );

  test('auditLogFiltersProvider resolves the dropdown options', () async {
    final filters = await container.read(auditLogFiltersProvider.future);
    expect(filters.modules, ['companies']);
    expect(filters.actions, ['company_created']);
  });
}
