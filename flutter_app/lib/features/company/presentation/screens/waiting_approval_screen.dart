import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/i18n/locale_provider.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/company_join_request.dart';
import '../../domain/value_objects/join_request_status.dart';
import '../providers/company_providers.dart';
import '../widgets/company_role_x.dart';

/// Shown while `profiles.status = 'pending'`. Stage 4 Part 1 replaced
/// the 8-second `Timer.periodic` poll this screen used to have with
/// [myMembershipRealtimeProvider] — a Realtime subscription on
/// `profiles` (see that provider's own doc comment for exactly how a
/// director's approve/reject elsewhere reaches this screen instantly
/// instead of on the next poll tick).
class WaitingApprovalScreen extends ConsumerStatefulWidget {
  const WaitingApprovalScreen({super.key});

  @override
  ConsumerState<WaitingApprovalScreen> createState() =>
      _WaitingApprovalScreenState();
}

class _WaitingApprovalScreenState extends ConsumerState<WaitingApprovalScreen> {
  /// Used by the manual pull-to-refresh only — the Realtime
  /// subscription itself already keeps things current without this.
  Future<void> _manualRefresh() async {
    try {
      await Supabase.instance.client.auth.refreshSession();
    } catch (_) {
      // ignore — Realtime will still catch the next actual change
    }
    if (!mounted) return;
    ref.invalidate(myJoinRequestsProvider);
  }

  Future<void> _withdraw(String requestId) async {
    final strings = ref.read(appStringsProvider);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.waitingApprovalWithdrawConfirmTitle),
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
        .read(membershipControllerProvider.notifier)
        .withdraw(requestId);
    if (!mounted) return;
    if (failure != null) {
      AppToast.show(failure.message, tone: ToastTone.error);
      return;
    }
    AppToast.show(
      strings.waitingApprovalWithdrawnToast,
      tone: ToastTone.success,
    );
    context.go(RoutePaths.onboarding);
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(myMembershipRealtimeProvider);
    final strings = ref.watch(appStringsProvider);
    final requestsAsync = ref.watch(myJoinRequestsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.waitingApprovalTitle),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.logOut),
            onPressed: () => ref.read(signOutUseCaseProvider).call(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _manualRefresh,
        child: requestsAsync.when(
          loading: () => const LoadingView(),
          error: (error, _) => ErrorView(
            message: strings.commonError,
            retryLabel: strings.commonRetry,
            onRetry: () => ref.invalidate(myJoinRequestsProvider),
          ),
          data: (requests) {
            if (requests.isEmpty) {
              return EmptyView(
                title: strings.waitingApprovalEmptyTitle,
                icon: LucideIcons.inbox,
                action: () => context.go(RoutePaths.onboarding),
                actionLabel: strings.waitingApprovalTryAgainAction,
              );
            }
            final latest = requests.first;
            return ListView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              children: [
                _RequestCard(
                  request: latest,
                  strings: strings,
                  onWithdraw: () => _withdraw(latest.id),
                  onTryAgain: () => context.go(RoutePaths.onboarding),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({
    required this.request,
    required this.strings,
    required this.onWithdraw,
    required this.onTryAgain,
  });

  final CompanyJoinRequest request;
  final dynamic strings;
  final VoidCallback onWithdraw;
  final VoidCallback onTryAgain;

  @override
  Widget build(BuildContext context) {
    final isPending = request.status == JoinRequestStatus.pending;
    final isRejected = request.status == JoinRequestStatus.rejected;
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm');

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.skyDeep.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                isPending ? LucideIcons.clock : LucideIcons.xCircle,
                color: isPending ? AppColors.warning : AppColors.danger,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                isPending
                    ? strings.waitingApprovalStatusPending
                    : strings.waitingApprovalStatusRejected,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _row(
            context,
            strings.waitingApprovalCompanyLabel,
            request.companyName,
          ),
          _row(
            context,
            strings.waitingApprovalRoleLabel,
            request.requestedRole.label(strings),
          ),
          _row(
            context,
            strings.waitingApprovalSubmittedLabel,
            dateFormat.format(request.createdAt),
          ),
          if (isRejected && request.rejectionReason != null)
            _row(
              context,
              strings.waitingApprovalRejectionReasonLabel,
              request.rejectionReason!,
            ),
          const SizedBox(height: AppSpacing.xl),
          if (isPending)
            AppButton(
              label: strings.waitingApprovalWithdrawAction,
              variant: AppButtonVariant.destructive,
              onPressed: onWithdraw,
              icon: LucideIcons.x,
            )
          else if (isRejected)
            AppButton(
              label: strings.waitingApprovalTryAgainAction,
              onPressed: onTryAgain,
              icon: LucideIcons.refreshCw,
            ),
        ],
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
}
