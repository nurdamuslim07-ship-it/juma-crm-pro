import '../../../../core/widgets/press_motion.dart';
import '../../../measurements/measurement_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/i18n/app_strings.dart';
import '../../../../core/i18n/locale_provider.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/glass/liquid_glass.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/widgets/stat_card.dart';
import '../../../../core/widgets/brand_mark.dart';
import '../../../../core/theme/theme_mode_provider.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../notifications/presentation/widgets/notification_bell.dart';
import '../../domain/entities/dashboard_summary.dart';
import '../providers/dashboard_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final user = ref.watch(currentUserProvider);
    final summaryAsync = ref.watch(dashboardSummaryProvider);

    final isFinance =
        user?.isDirector == true || user?.hasRole('accountant') == true;
    final isProduction =
        user?.isDirector == true ||
        user?.hasRole('workshop_manager') == true ||
        user?.hasRole('master') == true ||
        user?.hasRole('assistant') == true ||
        user?.hasRole('manager') == true;
    final isWarehouse =
        user?.isDirector == true ||
        user?.hasRole('workshop_manager') == true ||
        user?.hasRole('warehouse') == true;
    final isLogistics =
        user?.isDirector == true ||
        user?.hasRole('manager') == true ||
        user?.hasRole('workshop_manager') == true ||
        user?.hasRole('installer') == true;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => ref.invalidate(dashboardSummaryProvider),
          child: ListView(
            padding: context.pageInsets.copyWith(bottom: 120),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'JUMA UI',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: AppColors.skyDeep,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        Text(
                          strings.navDashboard,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: strings.settingsTheme,
                    onPressed: () =>
                        ref.read(themeModeProvider.notifier).state =
                            Theme.of(context).brightness == Brightness.dark
                            ? ThemeMode.light
                            : ThemeMode.dark,
                    icon: Icon(
                      Theme.of(context).brightness == Brightness.dark
                          ? LucideIcons.sun
                          : LucideIcons.moon,
                    ),
                  ),
                  const NotificationBell(),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              LiquidGlass(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    const BrandMark(size: 64),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            strings.dashboardGreetingPrefix,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            user?.fullName ?? '',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            strings.authWelcomeSubtitle,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    if (!context.isMobile)
                      Icon(
                        LucideIcons.armchair,
                        size: 90,
                        color: AppColors.blue.withValues(alpha: .35),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Text(
                strings.dashboardModulesTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.md),
              _ModuleGrid(strings: strings),
              const SizedBox(height: AppSpacing.xxl),
              summaryAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.huge),
                  child: LoadingView(),
                ),
                error: (error, _) => Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.huge,
                  ),
                  child: ErrorView(
                    message: strings.dashboardLoadError,
                    retryLabel: strings.commonRetry,
                    onRetry: () => ref.invalidate(dashboardSummaryProvider),
                  ),
                ),
                data: (summary) => _SummaryGrid(
                  summary: summary,
                  strings: strings,
                  isFinance: isFinance,
                  isProduction: isProduction,
                  isWarehouse: isWarehouse,
                  isLogistics: isLogistics,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({
    required this.summary,
    required this.strings,
    required this.isFinance,
    required this.isProduction,
    required this.isWarehouse,
    required this.isLogistics,
  });

  final DashboardSummary summary;
  final AppStrings strings;
  final bool isFinance;
  final bool isProduction;
  final bool isWarehouse;
  final bool isLogistics;

  @override
  Widget build(BuildContext context) {
    final tiles = <Widget>[
      StatCard(
        label: strings.dashboardActiveOrders,
        value: '${summary.activeOrdersCount}',
        icon: LucideIcons.clipboardList,
      ),
      StatCard(
        label: strings.dashboardMyOpenTasks,
        value: '${summary.myOpenTasksCount}',
        icon: LucideIcons.listChecks,
      ),
      StatCard(
        label: strings.dashboardTodayTasks,
        value: '${summary.myTodayTasksCount}',
        icon: LucideIcons.calendarCheck,
        tone: summary.myTodayTasksCount > 0
            ? StatTone.warning
            : StatTone.neutral,
      ),
      if (isProduction)
        StatCard(
          label: strings.dashboardDelayedOrders,
          value: '${summary.delayedOrdersCount}',
          icon: LucideIcons.alertTriangle,
          tone: summary.delayedOrdersCount > 0
              ? StatTone.danger
              : StatTone.success,
        ),
      if (isProduction)
        StatCard(
          label: strings.dashboardCompletedThisMonth,
          value: '${summary.completedThisMonthCount}',
          icon: LucideIcons.checkCircle2,
          tone: StatTone.success,
        ),
      if (isWarehouse)
        StatCard(
          label: strings.dashboardLowStock,
          value: '${summary.lowStockMaterialsCount}',
          icon: LucideIcons.packageX,
          tone: summary.lowStockMaterialsCount > 0
              ? StatTone.warning
              : StatTone.neutral,
        ),
      if (isLogistics)
        StatCard(
          label: strings.dashboardUpcomingDeliveries,
          value: '${summary.upcomingDeliveriesCount}',
          icon: LucideIcons.truck,
        ),
      if (isFinance) ...[
        StatCard(
          label: strings.dashboardTotalContractAmount,
          value: AppFormatters.tenge(summary.totalContractAmountTiyn),
          icon: LucideIcons.fileText,
        ),
        StatCard(
          label: strings.dashboardPaymentsReceived,
          value: AppFormatters.tenge(summary.paymentsReceivedTiyn),
          icon: LucideIcons.wallet,
          tone: StatTone.success,
        ),
        StatCard(
          label: strings.dashboardRemainingDebt,
          value: AppFormatters.tenge(summary.remainingDebtTiyn),
          icon: LucideIcons.circleDollarSign,
          tone: summary.remainingDebtTiyn > 0
              ? StatTone.warning
              : StatTone.success,
        ),
        StatCard(
          label: strings.dashboardExpenses,
          value: AppFormatters.tenge(summary.expensesTiyn),
          icon: LucideIcons.receipt,
        ),
      ],
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns =
            constraints.maxWidth < 300 ||
                MediaQuery.textScalerOf(context).scale(14) > 22
            ? 1
            : context.dashboardColumns;
        final width = (constraints.maxWidth - (columns - 1) * 10) / columns;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final tile in tiles)
              SizedBox(
                width:
                    tile is StatCard && tile.value.contains('₸') && columns == 2
                    ? constraints.maxWidth
                    : width,
                child: tile,
              ),
          ],
        );
      },
    );
  }
}

class _ModuleGrid extends ConsumerWidget {
  const _ModuleGrid({required this.strings});
  final AppStrings strings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modules = [
      (
        RoutePaths.measurements,
        LucideIcons.ruler,
        ref.watch(measurementStringsProvider).title,
      ),
      (RoutePaths.orders, LucideIcons.clipboardList, strings.navOrders),
      (RoutePaths.clients, LucideIcons.users, strings.navClients),
      (RoutePaths.payments, LucideIcons.wallet, strings.navPayments),
      (RoutePaths.employees, LucideIcons.userCog, strings.navEmployees),
      (RoutePaths.partners, LucideIcons.briefcase, strings.navPartners),
      (RoutePaths.analytics, LucideIcons.barChart3, strings.navAnalytics),
      (RoutePaths.production, LucideIcons.factory, strings.navProduction),
      (RoutePaths.warehouse, LucideIcons.warehouse, strings.navWarehouse),
      (RoutePaths.purchases, LucideIcons.shoppingCart, strings.navPurchases),
      (RoutePaths.settings, LucideIcons.settings, strings.navSettings),
      (RoutePaths.quickEstimate, LucideIcons.calculator, "Тез есеп"),
    ];

    final dark = Theme.of(context).brightness == Brightness.dark;
    const colors = [
      Color(0xFF0B9C98),
      Color(0xFF4771ED),
      Color(0xFF8860C9),
      Color(0xFF179D75),
      Color(0xFF527BA3),
      Color(0xFFC38535),
      Color(0xFF8363D3),
      Color(0xFFD17648),
      Color(0xFF3D9696),
      Color(0xFFC36288),
      Color(0xFF718096),
      Color(0xFF138F9D),
    ];
    return Column(
      children: [
        Row(
          children: [
            for (var i = 0; i < 2; i++) ...[
              if (i > 0) const SizedBox(width: 12),
              Expanded(
                child: MotionInkWell(
                  borderRadius: BorderRadius.circular(26),
                  onTap: () => context.go(modules[i].$1),
                  child: Container(
                    height: 152,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(26),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          colors[i],
                          Color.lerp(colors[i], const Color(0xFF162953), .35)!,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: colors[i].withValues(alpha: .18),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          right: -18,
                          top: -18,
                          child: Container(
                            width: 106,
                            height: 106,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: .12),
                                width: 20,
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    modules[i].$2,
                                    color: Colors.white,
                                    size: 29,
                                  ),
                                  const Spacer(),
                                  Icon(
                                    Icons.north_east_rounded,
                                    color: Colors.white.withValues(alpha: .65),
                                    size: 19,
                                  ),
                                ],
                              ),
                              const Spacer(),
                              Text(
                                modules[i].$3,
                                maxLines: 2,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                width: 28,
                                height: 3,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: .5),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) => GridView.builder(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: constraints.maxWidth < 340
                  ? 1
                  : constraints.maxWidth < 700
                  ? 2
                  : 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              mainAxisExtent: 76,
            ),
            itemCount: modules.length - 2,
            itemBuilder: (context, index) {
              final i = index + 2;
              final module = modules[i];
              return MotionInkWell(
                borderRadius: BorderRadius.circular(22),
                onTap: () => context.go(module.$1),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: (dark ? const Color(0xFF1C2C42) : Colors.white)
                        .withValues(alpha: .7),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: (dark ? Colors.white : colors[i]).withValues(
                        alpha: .09,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 42,
                        decoration: BoxDecoration(
                          color: colors[i].withValues(alpha: .12),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Icon(
                          module.$2,
                          color: dark
                              ? Color.lerp(colors[i], Colors.white, .35)
                              : colors[i],
                          size: 21,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          module.$3,
                          maxLines: 2,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
