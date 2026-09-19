import '../../../../core/widgets/app_back_button.dart';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/i18n/locale_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../domain/entities/audit_log_entry.dart';

/// Receives its [entry] via GoRouter's `extra` (see AuditLogScreen's
/// `context.push(..., extra: entry)`) — no separate `get_audit_log(id)`
/// fetch needed since the list row already has everything this detail
/// view shows.
class AuditLogDetailScreen extends ConsumerWidget {
  const AuditLogDetailScreen({super.key, required this.entry});

  final AuditLogEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm:ss');
    const encoder = JsonEncoder.withIndent('  ');

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: Text(strings.auditLogDetailTitle),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.action,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: AppSpacing.lg),
              _row(context, strings.auditLogModuleLabel, entry.entityType),
              if (entry.entityId != null)
                _row(context, strings.auditLogEntityIdLabel, entry.entityId!),
              _row(
                context,
                strings.auditLogEmployeeLabel,
                entry.actorName ?? '—',
              ),
              _row(
                context,
                strings.auditLogDateLabel,
                dateFormat.format(entry.createdAt),
              ),
              if (entry.before != null) ...[
                const SizedBox(height: AppSpacing.lg),
                Text(
                  strings.auditLogBeforeLabel,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                _jsonBlock(context, encoder.convert(entry.before)),
              ],
              if (entry.after != null) ...[
                const SizedBox(height: AppSpacing.lg),
                Text(
                  strings.auditLogAfterLabel,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                _jsonBlock(context, encoder.convert(entry.after)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }

  Widget _jsonBlock(BuildContext context, String json) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.skyDeep.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: SelectableText(
        json,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
      ),
    );
  }
}
