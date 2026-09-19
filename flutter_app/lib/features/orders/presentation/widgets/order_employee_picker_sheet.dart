import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/i18n/locale_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/debounced_search_controller.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/state_views.dart';
import '../../domain/entities/employee_option.dart';
import '../providers/order_providers.dart';

/// Requirement #14 ("Жауапты қызметкер"): picks from `profiles`
/// directly (see [EmployeeOption]) since no Employees feature module
/// exists yet — same local-search pattern as
/// [OrderClientPickerSheet].
class OrderEmployeePickerSheet extends ConsumerStatefulWidget {
  const OrderEmployeePickerSheet({super.key});

  static Future<EmployeeOption?> open(BuildContext context) {
    return showAppBottomSheet<EmployeeOption>(
      context: context,
      child: const OrderEmployeePickerSheet(),
    );
  }

  @override
  ConsumerState<OrderEmployeePickerSheet> createState() =>
      _OrderEmployeePickerSheetState();
}

class _OrderEmployeePickerSheetState
    extends ConsumerState<OrderEmployeePickerSheet> {
  late final _search = DebouncedSearchController(
    debounce: const Duration(milliseconds: 300),
    onSearch: (value) => setState(() => _future = _fetch(value)),
  );
  late Future<List<EmployeeOption>> _future;

  @override
  void initState() {
    super.initState();
    _future = _fetch('');
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<List<EmployeeOption>> _fetch(String query) {
    return ref
        .read(getEmployeeOptionsUseCaseProvider)
        .call(searchQuery: query)
        .then(
          (either) => either.match((failure) => throw failure, (data) => data),
        );
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);

    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.75,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            strings.orderSelectEmployeeTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _search.textController,
            onChanged: _search.onChanged,
            decoration: InputDecoration(
              hintText: strings.commonSearch,
              prefixIcon: const Icon(LucideIcons.search, size: 20),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Flexible(
            child: FutureBuilder<List<EmployeeOption>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.xxxl),
                    child: LoadingView(),
                  );
                }
                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xxxl,
                    ),
                    child: ErrorView(message: strings.dashboardLoadError),
                  );
                }
                final employees = snapshot.data ?? [];
                if (employees.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xxxl,
                    ),
                    child: EmptyView(
                      icon: LucideIcons.userX,
                      title: strings.commonEmpty,
                    ),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: employees.length,
                  itemBuilder: (context, index) {
                    final employee = employees[index];
                    return ListTile(
                      onTap: () => Navigator.of(context).pop(employee),
                      leading: CircleAvatar(
                        backgroundColor: AppColors.indigo.withValues(
                          alpha: 0.15,
                        ),
                        child: Text(
                          employee.fullName.isNotEmpty
                              ? employee.fullName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: AppColors.indigo,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      title: Text(employee.fullName),
                      subtitle: employee.phone != null
                          ? Text(employee.phone!)
                          : null,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
