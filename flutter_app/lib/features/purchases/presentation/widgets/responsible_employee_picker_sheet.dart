import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/i18n/locale_provider.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../employees/domain/entities/employee.dart';
import '../../../employees/presentation/providers/employee_providers.dart';

/// Requirement: "Жауапты қызметкер" (responsible employee) picker.
/// Reuses [getEmployeesUseCaseProvider] directly (not the shared
/// `employeesListProvider`), same reasoning as [SupplierPickerSheet] —
/// avoids mutating the Employees screen's own filter state. Note
/// [Employee.userId] (not [Employee.id]) is what `purchase_orders.
/// responsible_employee_id` references (`profiles.id`) — same
/// distinction Production's `get_masters()` makes.
class ResponsibleEmployeePickerSheet extends ConsumerStatefulWidget {
  const ResponsibleEmployeePickerSheet({super.key, this.currentUserId});

  final String? currentUserId;

  static Future<Employee?> open(BuildContext context, {String? currentUserId}) {
    return showAppBottomSheet<Employee>(
      context: context,
      child: ResponsibleEmployeePickerSheet(currentUserId: currentUserId),
    );
  }

  @override
  ConsumerState<ResponsibleEmployeePickerSheet> createState() =>
      _ResponsibleEmployeePickerSheetState();
}

class _ResponsibleEmployeePickerSheetState
    extends ConsumerState<ResponsibleEmployeePickerSheet> {
  late final Future<List<Employee>> _future = ref
      .read(getEmployeesUseCaseProvider)
      .call()
      .then((either) => either.match((failure) => throw failure, (d) => d));

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          strings.purchasesSelectEmployeeTitle,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.lg),
        FutureBuilder<List<Employee>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                child: LoadingView(),
              );
            }
            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                child: Text(strings.purchasesEmployeesLoadError),
              );
            }
            final employees = snapshot.data ?? const [];
            if (employees.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                child: Text(strings.purchasesNoEmployeesAvailable),
              );
            }
            return Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final employee in employees)
                    ListTile(
                      onTap: () => Navigator.of(context).pop(employee),
                      leading: const Icon(LucideIcons.user),
                      trailing: employee.userId == widget.currentUserId
                          ? const Icon(LucideIcons.check, size: 18)
                          : null,
                      title: Text(
                        employee.fullName,
                        style: TextStyle(
                          fontWeight: employee.userId == widget.currentUserId
                              ? FontWeight.w700
                              : null,
                        ),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
