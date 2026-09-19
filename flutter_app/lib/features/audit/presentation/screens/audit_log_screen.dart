import '../../../../core/widgets/app_back_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/i18n/locale_provider.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/debounced_search_controller.dart';
import '../../../../core/widgets/state_views.dart';
import '../../domain/entities/audit_log_entry.dart';
import '../../domain/entities/audit_log_query.dart';
import '../providers/audit_log_providers.dart';
import '../widgets/audit_log_filters_sheet.dart';

/// Director-only (see `audit_logs_select_director` RLS policy) —
/// reachable from Settings, same "hide the entry point, RLS is the
/// real gate" pattern as every other role-restricted screen in this
/// app.
class AuditLogScreen extends ConsumerStatefulWidget {
  const AuditLogScreen({super.key});

  @override
  ConsumerState<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends ConsumerState<AuditLogScreen> {
  late final _search = DebouncedSearchController(
    onSearch: (value) {
      final current = ref.read(auditLogQueryProvider);
      ref.read(auditLogQueryProvider.notifier).state = current.copyWith(
        search: value,
        clearSearch: value.isEmpty,
        offset: 0,
      );
    },
  );

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _goToPage(int newOffset) {
    final current = ref.read(auditLogQueryProvider);
    ref.read(auditLogQueryProvider.notifier).state = current.copyWith(
      offset: newOffset,
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);
    final query = ref.watch(auditLogQueryProvider);
    final pageAsync = ref.watch(auditLogsProvider);

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: Text(strings.auditLogTitle),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.listFilter),
            tooltip: strings.auditLogFiltersTitle,
            onPressed: () => AuditLogFiltersSheet.open(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _search.textController,
              onChanged: _search.onChanged,
              decoration: InputDecoration(
                hintText: strings.commonSearch,
                prefixIcon: const Icon(LucideIcons.search, size: 20),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: pageAsync.when(
                loading: () => const LoadingView(),
                error: (error, _) => ErrorView(
                  message: strings.commonError,
                  retryLabel: strings.commonRetry,
                  onRetry: () => ref.invalidate(auditLogsProvider),
                ),
                data: (page) {
                  if (page.entries.isEmpty) {
                    return EmptyView(
                      icon: LucideIcons.fileText,
                      title: strings.commonEmpty,
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () async => ref.invalidate(auditLogsProvider),
                    child: ListView.separated(
                      itemCount: page.entries.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, index) => _AuditLogTile(
                        entry: page.entries[index],
                        onTap: () => context.push(
                          RoutePaths.auditLogDetail(page.entries[index].id),
                          extra: page.entries[index],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            pageAsync.maybeWhen(
              data: (page) => _Pager(
                query: query,
                totalCount: page.totalCount,
                onPageChange: _goToPage,
              ),
              orElse: () => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuditLogTile extends StatelessWidget {
  const _AuditLogTile({required this.entry, required this.onTap});

  final AuditLogEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm');
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: AppColors.skyDeep.withValues(alpha: 0.15),
        child: const Icon(LucideIcons.fileText, color: AppColors.skyDeep),
      ),
      title: Text(entry.action),
      subtitle: Text(
        '${entry.entityType} · ${entry.actorName ?? '—'} · '
        '${dateFormat.format(entry.createdAt)}',
      ),
      trailing: const Icon(LucideIcons.chevronRight, size: 18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }
}

class _Pager extends StatelessWidget {
  const _Pager({
    required this.query,
    required this.totalCount,
    required this.onPageChange,
  });

  final AuditLogQuery query;
  final int totalCount;
  final ValueChanged<int> onPageChange;

  @override
  Widget build(BuildContext context) {
    final currentPage = (query.offset ~/ query.limit) + 1;
    final totalPages = (totalCount / query.limit).ceil().clamp(1, 999999);
    final hasPrev = query.offset > 0;
    final hasNext = query.offset + query.limit < totalCount;

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(LucideIcons.chevronLeft),
            onPressed: hasPrev
                ? () => onPageChange(query.offset - query.limit)
                : null,
          ),
          Text('$currentPage / $totalPages'),
          IconButton(
            icon: const Icon(LucideIcons.chevronRight),
            onPressed: hasNext
                ? () => onPageChange(query.offset + query.limit)
                : null,
          ),
        ],
      ),
    );
  }
}
