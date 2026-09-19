import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/widgets/press_motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/i18n/locale_provider.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/debounced_search_controller.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/employee_providers.dart';
import '../widgets/employee_list_tile.dart';
import '../widgets/employee_role_picker_sheet.dart';
import '../widgets/employee_role_x.dart';
import '../widgets/employee_status_picker_sheet.dart';

/// Requirement: "Қызметкерлер тізімін директор және менеджер көре
/// алады". Everyone else's `get_employees()` call still succeeds
/// (it's what backs their own profile view elsewhere), but this
/// SCREEN is only reachable for director/manager — see
/// core/router/app_router.dart's "Көбірек" sheet and this screen's
/// own guard below, which is UI convenience only: the real
/// enforcement is that get_employees() returns just one row (their
/// own) to anyone without employees.read/employees.read_financial.
class EmployeesListScreen extends ConsumerStatefulWidget {
  const EmployeesListScreen({super.key});

  @override
  ConsumerState<EmployeesListScreen> createState() =>
      _EmployeesListScreenState();
}

class _EmployeesListScreenState extends ConsumerState<EmployeesListScreen> {
  late final _search = DebouncedSearchController(
    onSearch: (value) =>
        ref.read(employeeSearchQueryProvider.notifier).state = value,
  );

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _pickRole() async {
    final picked = await EmployeeRolePickerSheet.open(
      context,
      current: ref.read(employeeRoleFilterProvider),
    );
    if (picked != null) {
      ref.read(employeeRoleFilterProvider.notifier).state = picked;
    }
  }

  Future<void> _pickStatus() async {
    final result = await EmployeeStatusPickerSheet.open(
      context,
      current: ref.read(employeeActiveFilterProvider),
    );
    final unwrapped = unwrapPickedStatus(result);
    if (unwrapped.picked) {
      ref.read(employeeActiveFilterProvider.notifier).state = unwrapped.value;
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(employeesRealtimeProvider);
    final strings = ref.watch(appStringsProvider);
    final employeesAsync = ref.watch(employeesListProvider);
    final currentUser = ref.watch(currentUserProvider);
    final isDirector = currentUser?.isDirector ?? false;
    final roleFilter = ref.watch(employeeRoleFilterProvider);
    final activeFilter = ref.watch(employeeActiveFilterProvider);

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: Text(strings.navEmployees),
        actions: isDirector
            ? [
                IconButton(
                  icon: const Icon(LucideIcons.userCheck),
                  tooltip: strings.companyRequestsTitle,
                  onPressed: () => context.push(RoutePaths.companyRequests),
                ),
              ]
            : null,
      ),
      floatingActionButton: isDirector
          ? FloatingActionButton(
              onPressed: () async {
                final created = await context.push<bool>(
                  RoutePaths.employeeNew,
                );
                if (created == true) ref.invalidate(employeesListProvider);
              },
              child: const Icon(LucideIcons.plus),
            )
          : null,
      body: Padding(
        padding: context.pageInsets,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _search.textController,
              onChanged: _search.onChanged,
              decoration: InputDecoration(
                hintText: strings.employeesSearchHint,
                prefixIcon: const Icon(LucideIcons.search, size: 20),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _FilterButton(
                    icon: LucideIcons.shieldQuestion,
                    label:
                        roleFilter?.label(strings) ??
                        strings.employeeFilterAllRoles,
                    onTap: _pickRole,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _FilterButton(
                    icon: LucideIcons.userCheck,
                    label: switch (activeFilter) {
                      true => strings.employeeFilterActive,
                      false => strings.employeeFilterInactive,
                      null => strings.employeeFilterAllStatuses,
                    },
                    onTap: _pickStatus,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Expanded(
              child: employeesAsync.when(
                loading: () => const LoadingView(),
                error: (error, _) => ErrorView(
                  message: strings.dashboardLoadError,
                  retryLabel: strings.commonRetry,
                  onRetry: () => ref.invalidate(employeesListProvider),
                ),
                data: (employees) {
                  if (employees.isEmpty) {
                    return EmptyView(
                      icon: LucideIcons.users,
                      title: strings.employeesEmptyTitle,
                      description: isDirector
                          ? strings.employeesEmptyDescription
                          : null,
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () async =>
                        ref.invalidate(employeesListProvider),
                    child: context.isMobile
                        ? ListView.builder(
                            itemCount: employees.length,
                            itemBuilder: (context, index) => EmployeeListTile(
                              employee: employees[index],
                              onTap: () => context.push(
                                RoutePaths.employeeDetail(
                                  employees[index].userId,
                                ),
                              ),
                            ),
                          )
                        : GridView.builder(
                            gridDelegate:
                                const SliverGridDelegateWithMaxCrossAxisExtent(
                                  maxCrossAxisExtent: 420,
                                  mainAxisExtent: 96,
                                  crossAxisSpacing: AppSpacing.md,
                                  mainAxisSpacing: AppSpacing.md,
                                ),
                            itemCount: employees.length,
                            itemBuilder: (context, index) => EmployeeListTile(
                              employee: employees[index],
                              onTap: () => context.push(
                                RoutePaths.employeeDetail(
                                  employees[index].userId,
                                ),
                              ),
                            ),
                          ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MotionInkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: AppColors.skyDeep.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppColors.skyDeep),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.skyDeep,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
