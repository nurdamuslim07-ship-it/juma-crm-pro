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
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/state_views.dart';
import '../../domain/entities/pending_company_request.dart';
import '../providers/company_providers.dart';
import '../widgets/company_role_picker_sheet.dart';
import '../widgets/company_role_x.dart';

/// Director/owner queue of incoming join requests — scoped server-side
/// to the caller's own company only (`get_pending_company_requests()`
/// filters by `auth_company_id()`; a cross-company approve/reject
/// attempt would fail P0002, but that path is unreachable from this
/// UI since the list itself never contains another company's rows).
/// Modeled on `features/employees/presentation/screens/employees_list_screen.dart`.
class DirectorPendingRequestsScreen extends ConsumerWidget {
  const DirectorPendingRequestsScreen({super.key});

  Future<void> _approve(
    BuildContext context,
    WidgetRef ref,
    PendingCompanyRequest request,
  ) async {
    final strings = ref.read(appStringsProvider);
    final overrideRole = await CompanyRolePickerSheet.open(
      context,
      current: request.requestedRole,
      title: strings.companyRequestsChangeRoleAction,
    );
    if (overrideRole == null) return;

    final failure = await ref
        .read(companyRequestActionControllerProvider.notifier)
        .approve(
          request.id,
          overrideRole: overrideRole == request.requestedRole
              ? null
              : overrideRole,
        );
    if (!context.mounted) return;
    if (failure != null) {
      AppToast.show(failure.message, tone: ToastTone.error);
      return;
    }
    AppToast.show(
      strings.companyRequestsApprovedToast,
      tone: ToastTone.success,
    );
    ref.invalidate(pendingCompanyRequestsProvider);
  }

  Future<void> _reject(
    BuildContext context,
    WidgetRef ref,
    PendingCompanyRequest request,
  ) async {
    final strings = ref.read(appStringsProvider);
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.companyRequestsRejectAction),
        content: AppTextField(
          label: strings.companyRequestsRejectReasonLabel,
          controller: reasonController,
        ),
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

    final failure = await ref
        .read(companyRequestActionControllerProvider.notifier)
        .reject(
          request.id,
          reason: reasonController.text.trim().isEmpty
              ? null
              : reasonController.text.trim(),
        );
    if (!context.mounted) return;
    if (failure != null) {
      AppToast.show(failure.message, tone: ToastTone.error);
      return;
    }
    AppToast.show(
      strings.companyRequestsRejectedToast,
      tone: ToastTone.success,
    );
    ref.invalidate(pendingCompanyRequestsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(joinRequestsRealtimeProvider);
    final strings = ref.watch(appStringsProvider);
    final requestsAsync = ref.watch(pendingCompanyRequestsProvider);

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: Text(strings.companyRequestsTitle),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.userPlus),
            tooltip: strings.companyRequestsInviteAction,
            onPressed: () => context.push(RoutePaths.companyInvite),
          ),
          IconButton(
            icon: const Icon(LucideIcons.users),
            tooltip: strings.companyRequestsMembersAction,
            onPressed: () => context.push(RoutePaths.companyMembers),
          ),
        ],
      ),
      body: Padding(
        padding: context.pageInsets,
        child: requestsAsync.when(
          loading: () => const LoadingView(),
          error: (error, _) => ErrorView(
            message: strings.commonError,
            retryLabel: strings.commonRetry,
            onRetry: () => ref.invalidate(pendingCompanyRequestsProvider),
          ),
          data: (requests) {
            if (requests.isEmpty) {
              return EmptyView(
                icon: LucideIcons.inbox,
                title: strings.companyRequestsEmptyTitle,
                description: strings.companyRequestsEmptyDescription,
              );
            }
            return RefreshIndicator(
              onRefresh: () async =>
                  ref.invalidate(pendingCompanyRequestsProvider),
              child: ListView.separated(
                itemCount: requests.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.md),
                itemBuilder: (context, index) => _RequestTile(
                  request: requests[index],
                  strings: strings,
                  onApprove: () => _approve(context, ref, requests[index]),
                  onReject: () => _reject(context, ref, requests[index]),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _RequestTile extends StatelessWidget {
  const _RequestTile({
    required this.request,
    required this.strings,
    required this.onApprove,
    required this.onReject,
  });

  final PendingCompanyRequest request;
  final dynamic strings;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm');
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.skyDeep.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.skyDeep.withValues(alpha: 0.15),
                child: Icon(
                  request.requestedRole.icon,
                  color: AppColors.skyDeep,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.fullName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (request.phone != null)
                      Text(
                        request.phone!,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            '${strings.companyRequestsRequestedRoleLabel}: '
            '${request.requestedRole.label(strings)}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (request.message != null && request.message!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              '${strings.companyRequestsMessageLabel}: ${request.message}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 4),
          Text(
            dateFormat.format(request.createdAt),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: strings.companyRequestsRejectAction,
                  variant: AppButtonVariant.destructive,
                  onPressed: onReject,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppButton(
                  label: strings.companyRequestsApproveAction,
                  onPressed: onApprove,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
