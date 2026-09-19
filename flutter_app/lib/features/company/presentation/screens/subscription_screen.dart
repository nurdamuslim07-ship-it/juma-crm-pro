import '../../../../core/widgets/app_back_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/i18n/locale_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/state_views.dart';
import '../../domain/entities/company_subscription_info.dart';
import '../providers/company_providers.dart';
import '../widgets/plan_card.dart';

/// Displays the caller's own company's plan/limits/usage
/// (`get_company_subscription_info()`) plus the full plan catalog as
/// cards (`get_subscription_plans()`) — see
/// supabase/migrations/20260713000038_company_settings_subscription.sql.
class SubscriptionScreen extends ConsumerWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(companiesRealtimeProvider);
    ref.watch(companySubscriptionsRealtimeProvider);
    final strings = ref.watch(appStringsProvider);
    final infoAsync = ref.watch(subscriptionInfoProvider);
    final plansAsync = ref.watch(subscriptionPlansProvider);

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: Text(strings.subscriptionTitle),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(subscriptionInfoProvider);
          ref.invalidate(subscriptionPlansProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          children: [
            infoAsync.when(
              loading: () => const LoadingView(),
              error: (error, _) => ErrorView(
                message: strings.commonError,
                retryLabel: strings.commonRetry,
                onRetry: () => ref.invalidate(subscriptionInfoProvider),
              ),
              data: (info) =>
                  _SubscriptionInfoCard(info: info, strings: strings),
            ),
            const SizedBox(height: AppSpacing.xxl),
            Text(
              strings.subscriptionPlansTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.lg),
            plansAsync.when(
              loading: () => const LoadingView(),
              error: (error, _) => ErrorView(
                message: strings.commonError,
                retryLabel: strings.commonRetry,
                onRetry: () => ref.invalidate(subscriptionPlansProvider),
              ),
              data: (plans) {
                final currentPlanKey = infoAsync.valueOrNull?.planKey;
                return Column(
                  children: [
                    for (final plan in plans)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: PlanCard(
                          plan: plan,
                          priceCustomLabel: strings.subscriptionContactSales,
                          maxEmployeesLabel:
                              strings.subscriptionMaxEmployeesLabel,
                          maxStorageLabel: strings.subscriptionMaxStorageLabel,
                          unlimitedLabel: strings.subscriptionUnlimitedLabel,
                          perMonthLabel: strings.subscriptionPerMonthLabel,
                          isCurrent: plan.key == currentPlanKey,
                          currentLabel: strings.subscriptionCurrentPlanBadge,
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SubscriptionInfoCard extends StatelessWidget {
  const _SubscriptionInfoCard({required this.info, required this.strings});

  final CompanySubscriptionInfo info;
  final dynamic strings;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd.MM.yyyy');
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                info.isExpired
                    ? Icons.error_outline
                    : Icons.check_circle_outline,
                color: info.isExpired ? AppColors.danger : AppColors.success,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                info.planNameKk,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (info.isTrial)
            _row(
              context,
              strings.subscriptionTrialStatusLabel,
              strings.subscriptionTrialActiveValue,
            ),
          _row(
            context,
            strings.subscriptionStartDateLabel,
            dateFormat.format(info.startedAt),
          ),
          if (info.expiresAt != null)
            _row(
              context,
              strings.subscriptionEndDateLabel,
              dateFormat.format(info.expiresAt!),
            ),
          if (info.remainingDays != null)
            _row(
              context,
              strings.subscriptionRemainingDaysLabel,
              '${info.remainingDays}',
            ),
          if (info.expiresAt != null)
            _row(
              context,
              strings.subscriptionNextPaymentLabel,
              dateFormat.format(info.expiresAt!),
            ),
          _row(
            context,
            strings.subscriptionCompanyStatusLabel,
            info.companyIsActive
                ? strings.subscriptionCompanyActiveValue
                : strings.subscriptionCompanyInactiveValue,
          ),
          _row(
            context,
            strings.subscriptionActiveUsersLabel,
            '${info.activeUsers}',
          ),
          _row(
            context,
            strings.subscriptionMaxEmployeesLabel,
            info.maxEmployees?.toString() ?? strings.subscriptionUnlimitedLabel,
          ),
          _row(
            context,
            strings.subscriptionMaxStorageLabel,
            info.maxStorageMb != null
                ? '${info.maxStorageMb} MB'
                : strings.subscriptionUnlimitedLabel,
          ),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
