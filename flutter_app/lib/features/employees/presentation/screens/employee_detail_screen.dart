import '../../../../core/widgets/app_back_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/i18n/locale_provider.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/launchers.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/employee.dart';
import '../providers/employee_providers.dart';
import '../widgets/employee_avatar.dart';
import '../widgets/employee_role_x.dart';
import '../widgets/salary_type_x.dart';
import '../widgets/self_profile_edit_sheet.dart';

class EmployeeDetailScreen extends ConsumerWidget {
  const EmployeeDetailScreen({super.key, required this.userId});
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final employeeAsync = ref.watch(employeeDetailProvider(userId));

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: Text(strings.navEmployees),
      ),
      body: employeeAsync.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorView(
          message: strings.employeeNotFound,
          retryLabel: strings.commonRetry,
          onRetry: () => ref.invalidate(employeeDetailProvider(userId)),
        ),
        data: (employee) => _EmployeeDetailBody(employee: employee),
      ),
    );
  }
}

class _EmployeeDetailBody extends ConsumerWidget {
  const _EmployeeDetailBody({required this.employee});
  final Employee employee;

  Future<void> _toggleActive(BuildContext context, WidgetRef ref) async {
    final strings = ref.read(appStringsProvider);

    if (employee.isActive) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(strings.employeeDeactivateConfirmTitle),
          content: Text(strings.employeeDeactivateConfirmBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(strings.commonCancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(strings.commonConfirm),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    final result = await ref
        .read(setEmployeeActiveUseCaseProvider)
        .call(employee.userId, !employee.isActive);
    if (!context.mounted) return;

    result.match(
      (failure) => AppToast.show(failure.message, tone: ToastTone.error),
      (_) {
        AppToast.show(
          employee.isActive
              ? strings.employeeDeactivatedToast
              : strings.employeeActivatedToast,
          tone: ToastTone.success,
        );
        ref.invalidate(employeeDetailProvider(employee.userId));
        ref.invalidate(employeesListProvider);
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final strings = ref.read(appStringsProvider);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.employeeDeleteConfirmTitle),
        content: Text(strings.employeeDeleteConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(strings.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              strings.commonDelete,
              style: const TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final result = await ref
        .read(deleteEmployeeUseCaseProvider)
        .call(employee.userId);
    if (!context.mounted) return;

    result.match(
      (failure) => AppToast.show(failure.message, tone: ToastTone.error),
      (_) {
        AppToast.show(strings.employeeDeletedToast, tone: ToastTone.success);
        ref.invalidate(employeesListProvider);
        context.pop(true);
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final textTheme = Theme.of(context).textTheme;
    final currentUser = ref.watch(currentUserProvider);
    final isDirector = currentUser?.isDirector ?? false;
    final isSelf = currentUser?.id == employee.userId;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            GlassCard(
              child: Column(
                children: [
                  EmployeeAvatar(
                    avatarUrl: employee.avatarUrl,
                    fullName: employee.fullName,
                    radius: 40,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(employee.fullName, style: textTheme.headlineSmall),
                  if (employee.role != null)
                    Text(
                      employee.role!.label(strings),
                      style: textTheme.bodyMedium,
                    ),
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color:
                          (employee.isActive
                                  ? AppColors.success
                                  : AppColors.textSecondaryLight)
                              .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      employee.isActive
                          ? strings.employeeStatusActive
                          : strings.employeeStatusInactive,
                      style: TextStyle(
                        color: employee.isActive
                            ? AppColors.success
                            : AppColors.textSecondaryLight,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  if (employee.phone != null) ...[
                    const SizedBox(height: AppSpacing.lg),
                    AppButton(
                      label: employee.phone!,
                      icon: LucideIcons.phone,
                      variant: AppButtonVariant.secondary,
                      onPressed: () async {
                        final ok = await AppLaunchers.call(employee.phone!);
                        if (!ok && context.mounted) {
                          AppToast.show(
                            strings.commonCannotOpenLink,
                            tone: ToastTone.error,
                          );
                        }
                      },
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoRow(
                    icon: LucideIcons.mail,
                    label: strings.employeeFormEmailLabel,
                    value: employee.email,
                  ),
                  _InfoRow(
                    icon: LucideIcons.calendarDays,
                    label: strings.employeeFormHireDateLabel,
                    value: employee.hireDate != null
                        ? AppFormatters.date(employee.hireDate!)
                        : strings.employeeNoHireDate,
                  ),
                  _InfoRow(
                    icon: LucideIcons.stickyNote,
                    label: strings.employeeFormNotesLabel,
                    value: employee.notes?.isNotEmpty == true
                        ? employee.notes!
                        : strings.employeeNoNotes,
                    isLast: !employee.hasFinancialAccess,
                  ),
                  if (employee.hasFinancialAccess) ...[
                    _InfoRow(
                      icon: LucideIcons.wallet,
                      label: strings.employeeFormSalaryTypeLabel,
                      value: employee.salaryType!.label(strings),
                    ),
                    _InfoRow(
                      icon: LucideIcons.banknote,
                      label: strings.employeeFormBaseSalaryLabel,
                      value: AppFormatters.tenge(employee.baseSalaryTiyn ?? 0),
                    ),
                    _InfoRow(
                      icon: LucideIcons.percent,
                      label: strings.employeeFormBonusPercentLabel,
                      value: AppFormatters.percent(employee.bonusPercent ?? 0),
                      isLast: true,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            if (isDirector) ...[
              AppButton(
                label: strings.commonEdit,
                icon: LucideIcons.pencil,
                variant: AppButtonVariant.secondary,
                onPressed: () async {
                  final changed = await context.push<bool>(
                    RoutePaths.employeeEdit(employee.userId),
                    extra: employee,
                  );
                  if (changed == true) {
                    ref.invalidate(employeeDetailProvider(employee.userId));
                    ref.invalidate(employeesListProvider);
                  }
                },
              ),
              const SizedBox(height: AppSpacing.md),
              AppButton(
                label: employee.isActive
                    ? strings.employeeDeactivateConfirmTitle
                    : strings.employeeActivatedToast,
                icon: employee.isActive
                    ? LucideIcons.userX
                    : LucideIcons.userCheck,
                variant: AppButtonVariant.secondary,
                onPressed: () => _toggleActive(context, ref),
              ),
              const SizedBox(height: AppSpacing.md),
              AppButton(
                label: strings.commonDelete,
                icon: LucideIcons.trash2,
                variant: AppButtonVariant.destructive,
                onPressed: () => _confirmDelete(context, ref),
              ),
            ] else if (isSelf)
              AppButton(
                label: strings.employeeChangeAvatar,
                icon: LucideIcons.pencil,
                variant: AppButtonVariant.secondary,
                onPressed: () async {
                  final changed = await SelfProfileEditSheet.open(
                    context,
                    employee: employee,
                  );
                  if (changed == true) {
                    ref.invalidate(employeeDetailProvider(employee.userId));
                  }
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isLast = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondaryLight),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: textTheme.bodySmall),
                Text(value, style: textTheme.bodyLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
