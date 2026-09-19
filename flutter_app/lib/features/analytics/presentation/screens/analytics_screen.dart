import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/widgets/press_motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/i18n/locale_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/widgets/stat_card.dart';
import '../../domain/analytics_period.dart';
import '../../domain/entities/analytics_summary.dart';
import '../providers/analytics_providers.dart';
import '../widgets/analytics_period_picker_sheet.dart';
import '../widgets/analytics_period_type_x.dart';
import '../widgets/employee_kpi_section.dart';
import '../widgets/kpi_comparison_card.dart';
import '../widgets/orders_by_status_section.dart';
import '../widgets/payment_methods_section.dart';
import '../widgets/top_clients_section.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final periodType = ref.watch(analyticsPeriodTypeProvider);
    final range = ref.watch(analyticsRangeProvider);
    final summaryAsync = ref.watch(analyticsSummaryProvider);

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: Text(strings.navAnalytics),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(analyticsSummaryProvider);
          ref.invalidate(analyticsPreviousSummaryProvider);
          ref.invalidate(employeeKpisProvider);
          ref.invalidate(topClientsProvider);
        },
        child: ListView(
          padding: context.pageInsets,
          children: [
            _PeriodControls(periodType: periodType, range: range),
            const SizedBox(height: AppSpacing.lg),
            summaryAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.huge),
                child: LoadingView(),
              ),
              error: (error, _) => Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.huge),
                child: ErrorView(
                  message: strings.analyticsLoadError,
                  retryLabel: strings.commonRetry,
                  onRetry: () => ref.invalidate(analyticsSummaryProvider),
                ),
              ),
              data: (summary) => _AnalyticsBody(summary: summary),
            ),
          ],
        ),
      ),
    );
  }
}

class _PeriodControls extends ConsumerWidget {
  const _PeriodControls({required this.periodType, required this.range});

  final AnalyticsPeriodType periodType;
  final DateRange range;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);

    return Row(
      children: [
        IconButton(
          icon: const Icon(LucideIcons.chevronLeft),
          onPressed: () {
            final current = ref.read(analyticsReferenceDateProvider);
            ref.read(analyticsReferenceDateProvider.notifier).state =
                shiftReferenceDate(periodType, current, -1);
          },
        ),
        Expanded(
          child: MotionInkWell(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            onTap: () async {
              final picked = await AnalyticsPeriodPickerSheet.open(
                context,
                current: periodType,
              );
              if (picked != null) {
                ref.read(analyticsPeriodTypeProvider.notifier).state = picked;
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: AppColors.skyDeep.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Column(
                children: [
                  Text(
                    periodType.label(strings),
                    style: const TextStyle(
                      color: AppColors.skyDeep,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    '${AppFormatters.date(range.start)} – '
                    '${AppFormatters.date(range.end)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ),
        IconButton(
          icon: const Icon(LucideIcons.chevronRight),
          onPressed: () {
            final current = ref.read(analyticsReferenceDateProvider);
            ref.read(analyticsReferenceDateProvider.notifier).state =
                shiftReferenceDate(periodType, current, 1);
          },
        ),
      ],
    );
  }
}

class _AnalyticsBody extends ConsumerWidget {
  const _AnalyticsBody({required this.summary});
  final AnalyticsSummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final previousAsync = ref.watch(analyticsPreviousSummaryProvider);
    final previous = previousAsync.valueOrNull;
    final employeeKpisAsync = ref.watch(employeeKpisProvider);

    final crossAxisCount = context.isMobile ? 1 : context.dashboardColumns;

    if (!summary.hasSalesAccess && !summary.hasFinancialAccess) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            child: Text(
              strings.analyticsOwnKpiOnlyNote,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          employeeKpisAsync.when(
            loading: () => const LoadingView(),
            error: (error, _) => ErrorView(
              message: strings.analyticsLoadError,
              retryLabel: strings.commonRetry,
              onRetry: () => ref.invalidate(employeeKpisProvider),
            ),
            data: (kpis) => EmployeeKpiSection(kpis: kpis),
          ),
        ],
      );
    }

    final salesCards = <Widget>[
      KpiComparisonCard(
        label: strings.analyticsTurnover,
        value: AppFormatters.tenge(summary.turnoverTiyn ?? 0),
        icon: LucideIcons.trendingUp,
        current: summary.turnoverTiyn,
        previous: previous?.turnoverTiyn,
      ),
      KpiComparisonCard(
        label: strings.analyticsOrdersCount,
        value: '${summary.ordersCount ?? 0}',
        icon: LucideIcons.clipboardList,
        current: summary.ordersCount,
        previous: previous?.ordersCount,
      ),
      KpiComparisonCard(
        label: strings.analyticsInstalledCount,
        value: '${summary.installedCount ?? 0}',
        icon: LucideIcons.checkCircle2,
        tone: StatTone.success,
        current: summary.installedCount,
        previous: previous?.installedCount,
      ),
      KpiComparisonCard(
        label: strings.analyticsNewClientsCount,
        value: '${summary.newClientsCount ?? 0}',
        icon: LucideIcons.userPlus,
        current: summary.newClientsCount,
        previous: previous?.newClientsCount,
      ),
      KpiComparisonCard(
        label: strings.analyticsAvgOrderAmount,
        value: AppFormatters.tenge(summary.avgOrderAmountTiyn ?? 0),
        icon: LucideIcons.calculator,
        current: summary.avgOrderAmountTiyn,
        previous: previous?.avgOrderAmountTiyn,
      ),
    ];

    final financialCards = <Widget>[
      KpiComparisonCard(
        label: strings.analyticsPaymentsReceived,
        value: AppFormatters.tenge(summary.paymentsReceivedTiyn ?? 0),
        icon: LucideIcons.wallet,
        tone: StatTone.success,
        current: summary.paymentsReceivedTiyn,
        previous: previous?.paymentsReceivedTiyn,
      ),
      KpiComparisonCard(
        label: strings.analyticsRemainingDebt,
        value: AppFormatters.tenge(summary.remainingDebtTiyn ?? 0),
        icon: LucideIcons.circleDollarSign,
        tone: (summary.remainingDebtTiyn ?? 0) > 0
            ? StatTone.warning
            : StatTone.success,
        higherIsBetter: false,
        current: summary.remainingDebtTiyn,
        previous: previous?.remainingDebtTiyn,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (summary.hasSalesAccess) ...[
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
            childAspectRatio: context.isMobile ? 2.6 : 1.3,
            children: salesCards,
          ),
          const SizedBox(height: AppSpacing.lg),
          OrdersByStatusSection(ordersByStatus: summary.ordersByStatus),
          const SizedBox(height: AppSpacing.lg),
          Consumer(
            builder: (context, ref, _) {
              final topClientsAsync = ref.watch(topClientsProvider);
              return topClientsAsync.when(
                loading: () => const LoadingView(),
                error: (error, _) => const SizedBox.shrink(),
                data: (clients) => clients.isEmpty
                    ? const SizedBox.shrink()
                    : Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                        child: TopClientsSection(clients: clients),
                      ),
              );
            },
          ),
        ],
        if (summary.hasFinancialAccess) ...[
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
            childAspectRatio: context.isMobile ? 2.6 : 1.3,
            children: financialCards,
          ),
          const SizedBox(height: AppSpacing.lg),
          PaymentMethodsSection(stats: summary.paymentMethodStats),
          const SizedBox(height: AppSpacing.lg),
        ],
        employeeKpisAsync.when(
          loading: () => const LoadingView(),
          error: (error, _) => ErrorView(
            message: strings.analyticsLoadError,
            retryLabel: strings.commonRetry,
            onRetry: () => ref.invalidate(employeeKpisProvider),
          ),
          data: (kpis) => EmployeeKpiSection(kpis: kpis),
        ),
      ],
    );
  }
}
