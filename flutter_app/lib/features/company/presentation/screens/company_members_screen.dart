import '../../../../core/widgets/app_back_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/i18n/locale_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../employees/presentation/providers/employee_providers.dart';
import '../../../employees/presentation/widgets/employee_role_x.dart';

/// Who belongs to this company and what role they hold — a lighter,
/// onboarding-context view than EmployeesListScreen (no salary/hire
/// date), backed by the SAME already-company-scoped `get_employees()`
/// RPC rather than a new backend endpoint (the 9 company-registration
/// RPCs have no "list members" call of their own — see
/// supabase/migrations/20260713000036_company_registration_module.sql,
/// which deliberately doesn't duplicate what get_employees() already
/// does correctly).
class CompanyMembersScreen extends ConsumerWidget {
  const CompanyMembersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(employeesRealtimeProvider);
    final strings = ref.watch(appStringsProvider);
    final employeesAsync = ref.watch(employeesListProvider);

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: Text(strings.companyMembersTitle),
      ),
      body: employeesAsync.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorView(
          message: strings.commonError,
          retryLabel: strings.commonRetry,
          onRetry: () => ref.invalidate(employeesListProvider),
        ),
        data: (members) {
          if (members.isEmpty) {
            return EmptyView(
              icon: LucideIcons.users,
              title: strings.companyMembersEmptyTitle,
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(employeesListProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: members.length,
              itemBuilder: (context, index) {
                final member = members[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.skyDeep.withValues(alpha: 0.15),
                    backgroundImage: member.avatarUrl != null
                        ? NetworkImage(member.avatarUrl!)
                        : null,
                    child: member.avatarUrl == null
                        ? Icon(
                            member.role?.icon ?? LucideIcons.user,
                            color: AppColors.skyDeep,
                          )
                        : null,
                  ),
                  title: Text(member.fullName),
                  subtitle: Text(
                    member.role != null
                        ? '${member.role!.label(strings)} · '
                              '${strings.companyMembersRoleLabel}'
                        : strings.companyMembersRoleLabel,
                  ),
                  trailing: member.isActive
                      ? null
                      : const Icon(
                          LucideIcons.userX,
                          color: AppColors.textSecondaryLight,
                          size: 18,
                        ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
