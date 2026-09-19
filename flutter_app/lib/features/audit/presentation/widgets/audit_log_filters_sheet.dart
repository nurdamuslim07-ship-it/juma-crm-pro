import '../../../../core/widgets/press_motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/i18n/locale_provider.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../employees/presentation/providers/employee_providers.dart';
import '../../domain/entities/audit_log_query.dart';
import '../providers/audit_log_providers.dart';

/// Module/Action/Employee/date-range filters in one sheet — see
/// AuditLogScreen, which opens this via its app bar filter action.
class AuditLogFiltersSheet extends ConsumerStatefulWidget {
  const AuditLogFiltersSheet({super.key});

  static Future<void> open(BuildContext context) {
    return showAppBottomSheet<void>(
      context: context,
      child: const AuditLogFiltersSheet(),
    );
  }

  @override
  ConsumerState<AuditLogFiltersSheet> createState() =>
      _AuditLogFiltersSheetState();
}

class _AuditLogFiltersSheetState extends ConsumerState<AuditLogFiltersSheet> {
  late AuditLogQuery _draft;

  @override
  void initState() {
    super.initState();
    _draft = ref.read(auditLogQueryProvider);
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 3),
      lastDate: now,
      initialDateRange: _draft.from != null && _draft.to != null
          ? DateTimeRange(start: _draft.from!, end: _draft.to!)
          : null,
    );
    if (range != null) {
      setState(() {
        _draft = _draft.copyWith(from: range.start, to: range.end);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);
    final filtersAsync = ref.watch(auditLogFiltersProvider);
    final employeesAsync = ref.watch(employeesListProvider);
    final dateFormat = DateFormat('dd.MM.yyyy');

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          strings.auditLogFiltersTitle,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.lg),
        MotionInkWell(
          onTap: _pickDateRange,
          child: InputDecorator(
            decoration: InputDecoration(labelText: strings.auditLogDateLabel),
            child: Text(
              _draft.from != null && _draft.to != null
                  ? '${dateFormat.format(_draft.from!)} — ${dateFormat.format(_draft.to!)}'
                  : strings.auditLogAllDatesLabel,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        filtersAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (error, _) => const SizedBox.shrink(),
          data: (filters) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<String?>(
                  initialValue: _draft.entityType,
                  decoration: InputDecoration(
                    labelText: strings.auditLogModuleLabel,
                  ),
                  items: [
                    DropdownMenuItem(
                      value: null,
                      child: Text(strings.auditLogAllModulesLabel),
                    ),
                    for (final module in filters.modules)
                      DropdownMenuItem(value: module, child: Text(module)),
                  ],
                  onChanged: (value) => setState(
                    () => _draft = _draft.copyWith(
                      entityType: value,
                      clearEntityType: value == null,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                DropdownButtonFormField<String?>(
                  initialValue: _draft.action,
                  decoration: InputDecoration(
                    labelText: strings.auditLogActionLabel,
                  ),
                  items: [
                    DropdownMenuItem(
                      value: null,
                      child: Text(strings.auditLogAllActionsLabel),
                    ),
                    for (final action in filters.actions)
                      DropdownMenuItem(value: action, child: Text(action)),
                  ],
                  onChanged: (value) => setState(
                    () => _draft = _draft.copyWith(
                      action: value,
                      clearAction: value == null,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        employeesAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (error, _) => const SizedBox.shrink(),
          data: (employees) {
            return DropdownButtonFormField<String?>(
              initialValue: _draft.actorId,
              decoration: InputDecoration(
                labelText: strings.auditLogEmployeeLabel,
              ),
              items: [
                DropdownMenuItem(
                  value: null,
                  child: Text(strings.auditLogAllEmployeesLabel),
                ),
                for (final employee in employees)
                  DropdownMenuItem(
                    value: employee.userId,
                    child: Text(employee.fullName),
                  ),
              ],
              onChanged: (value) => setState(
                () => _draft = _draft.copyWith(
                  actorId: value,
                  clearActorId: value == null,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: AppSpacing.xl),
        Row(
          children: [
            Expanded(
              child: AppButton(
                label: strings.auditLogClearFiltersAction,
                variant: AppButtonVariant.secondary,
                onPressed: () {
                  ref.read(auditLogQueryProvider.notifier).state =
                      const AuditLogQuery();
                  Navigator.of(context).pop();
                },
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: AppButton(
                label: strings.commonConfirm,
                onPressed: () {
                  ref.read(auditLogQueryProvider.notifier).state = _draft
                      .copyWith(offset: 0);
                  Navigator.of(context).pop();
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
