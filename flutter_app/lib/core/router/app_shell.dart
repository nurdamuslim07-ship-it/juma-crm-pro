import '../widgets/swipe_navigation.dart';
import '../widgets/press_motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../i18n/locale_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/glass/liquid_glass.dart';
import '../utils/responsive.dart';
import '../widgets/app_bottom_sheet.dart';
import '../widgets/offline_banner.dart';
import '../widgets/brand_mark.dart';
import 'route_paths.dart';
import 'quick_add_action.dart';

class _NavDestination {
  const _NavDestination(this.path, this.icon, this.labelBuilder);
  final String path;
  final IconData icon;
  final String Function(dynamic strings) labelBuilder;
}

final _allDestinations = <_NavDestination>[
  _NavDestination(
    RoutePaths.dashboard,
    LucideIcons.layoutDashboard,
    (s) => s.navDashboard,
  ),
  _NavDestination(
    RoutePaths.orders,
    LucideIcons.clipboardList,
    (s) => s.navOrders,
  ),
  _NavDestination(RoutePaths.clients, LucideIcons.users, (s) => s.navClients),
  _NavDestination(
    RoutePaths.payments,
    LucideIcons.wallet,
    (s) => s.navPayments,
  ),
  _NavDestination(
    RoutePaths.employees,
    LucideIcons.userCog,
    (s) => s.navEmployees,
  ),
  _NavDestination(
    RoutePaths.partners,
    LucideIcons.briefcase,
    (s) => s.navPartners,
  ),
  _NavDestination(
    RoutePaths.analytics,
    LucideIcons.barChart3,
    (s) => s.navAnalytics,
  ),
  _NavDestination(
    RoutePaths.production,
    LucideIcons.factory,
    (s) => s.navProduction,
  ),
  _NavDestination(
    RoutePaths.warehouse,
    LucideIcons.warehouse,
    (s) => s.navWarehouse,
  ),
  _NavDestination(
    RoutePaths.purchases,
    LucideIcons.shoppingCart,
    (s) => s.navPurchases,
  ),
  _NavDestination(
    RoutePaths.settings,
    LucideIcons.settings,
    (s) => s.navSettings,
  ),
];

/// Responsive shell chrome around the 8 top-level modules. Per
/// RESPONSIVE_LAYOUT.md's rule: this is the ONE place mobile vs.
/// desktop navigation genuinely diverges (bottom bar vs. sidebar) —
/// page *content* underneath (`navigationShell`) is never duplicated.
///
/// Mobile only has room for 4 primary destinations + a center quick-add
/// FAB (per MOBILE_NAVIGATION.md's original 5-slot design); the
/// remaining modules are reachable via a "Көбірек" (More) sheet rather
/// than an overcrowded bottom bar. Tablet/desktop show all 8 directly
/// in a sidebar since there's room.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final isCompact = context.isMobile;
    final shell = isCompact
        ? _MobileShell(navigationShell: navigationShell, strings: strings)
        : _DesktopShell(navigationShell: navigationShell, strings: strings);

    // Stage 4 Part 7 — the offline banner sits above every shell
    // screen regardless of mobile/desktop chrome; see
    // core/widgets/offline_banner.dart's own doc comment for scope.
    return Column(
      children: [
        const OfflineBanner(),
        Expanded(child: shell),
      ],
    );
  }
}

class _MobileShell extends StatelessWidget {
  const _MobileShell({required this.navigationShell, required this.strings});
  final StatefulNavigationShell navigationShell;
  final dynamic strings;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Reserve the navigation bar area so nested pages and their FABs
      // remain above it, including the device bottom safe area.
      extendBody: false,
      body: navigationShell,
      bottomNavigationBar: SwipeNavigation(
        openLabel: 'Мәзірді ашу / Открыть меню',
        closeLabel: 'Мәзірді жасыру / Скрыть меню',
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          child: LiquidGlass(
            borderRadius: BorderRadius.circular(32),
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: SizedBox(
              height: 64,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _tab(
                    context,
                    0,
                    LucideIcons.layoutDashboard,
                    strings.navDashboard,
                  ),
                  _tab(
                    context,
                    1,
                    LucideIcons.clipboardList,
                    strings.navOrders,
                  ),
                  PressMotion(
                    child: SizedBox(
                      width: 56,
                      height: 56,
                      child: FloatingActionButton(
                        heroTag: 'shell-quick-add',
                        onPressed: () => _openQuickAdd(context),
                        backgroundColor: AppColors.blue,
                        child: const Icon(
                          LucideIcons.plus,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  _tab(context, 2, LucideIcons.users, strings.navClients),
                  _MoreTab(strings: strings, navigationShell: navigationShell),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _tab(BuildContext context, int index, IconData icon, String label) {
    final selected = navigationShell.currentIndex == index;
    final color = selected
        ? AppColors.skyDeep
        : Theme.of(context).colorScheme.onSurfaceVariant;
    return MotionInkWell(
      onTap: () => navigationShell.goBranch(
        index,
        initialLocation: index == navigationShell.currentIndex,
      ),
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openQuickAdd(BuildContext context) async {
    final action = await showAppBottomSheet<QuickAddAction>(
      context: context,
      title: null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _QuickAddTile(
            icon: LucideIcons.userPlus,
            label: strings.quickAddNewClient,
            action: QuickAddAction.client,
          ),
          _QuickAddTile(
            icon: LucideIcons.filePlus,
            label: strings.quickAddNewOrder,
            action: QuickAddAction.order,
          ),
          _QuickAddTile(
            icon: LucideIcons.ruler,
            label: strings.quickAddNewMeasurement,
            action: QuickAddAction.measurement,
          ),
          _QuickAddTile(
            icon: LucideIcons.banknote,
            label: strings.quickAddNewPayment,
            action: QuickAddAction.payment,
          ),
          _QuickAddTile(
            icon: LucideIcons.receipt,
            label: strings.quickAddNewExpense,
            action: QuickAddAction.expense,
          ),
          _QuickAddTile(
            icon: LucideIcons.camera,
            label: strings.quickAddPhotoReport,
            action: QuickAddAction.photo,
          ),
        ],
      ),
    );
    if (context.mounted && action != null) {
      await openQuickAddAction(context, action);
    }
  }
}

class _QuickAddTile extends StatelessWidget {
  const _QuickAddTile({
    required this.icon,
    required this.label,
    required this.action,
  });
  final QuickAddAction action;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return PressMotion(
      child: ListTile(
        onTap: () => Navigator.of(context).pop(action),
        leading: CircleAvatar(
          backgroundColor: AppColors.skyDeep.withValues(alpha: 0.15),
          child: Icon(icon, color: AppColors.skyDeep, size: 20),
        ),
        title: Text(label, style: Theme.of(context).textTheme.bodyLarge),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

class _MoreTab extends StatelessWidget {
  const _MoreTab({required this.strings, required this.navigationShell});
  final dynamic strings;
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final onMoreScreen = ![0, 1, 2].contains(navigationShell.currentIndex);
    final color = onMoreScreen ? AppColors.blue : AppColors.textSecondaryLight;
    return MotionInkWell(
      onTap: () => showAppBottomSheet(
        context: context,
        title: 'Көбірек',
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * .65,
          ),
          child: SingleChildScrollView(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth < 300 ? 1 : 2;
                const accents = [
                  Color(0xFF179D75),
                  Color(0xFF527BA3),
                  Color(0xFFC38535),
                  Color(0xFF8363D3),
                  Color(0xFFD17648),
                  Color(0xFF3D9696),
                  Color(0xFFC36288),
                  Color(0xFF718096),
                ];
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final i in [3, 4, 5, 6, 7, 8, 9, 10])
                      SizedBox(
                        width:
                            (constraints.maxWidth - (columns - 1) * 12) /
                            columns,
                        child: _MoreListTile(
                          icon: _allDestinations[i].icon,
                          label: _allDestinations[i].labelBuilder(strings),
                          accent: accents[i - 3],
                          selected: navigationShell.currentIndex == i,
                          onTap: () {
                            Navigator.of(context).pop();
                            navigationShell.goBranch(
                              i,
                              initialLocation:
                                  i == navigationShell.currentIndex,
                            );
                          },
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.menu, color: color, size: 22),
            const SizedBox(height: 2),
            Text(
              'Көбірек',
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MoreListTile extends StatelessWidget {
  const _MoreListTile({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.accent,
    required this.selected,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color accent;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      selected: selected,
      child: MotionInkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: selected
                ? accent.withValues(alpha: dark ? .25 : .13)
                : (dark ? const Color(0xFF1C2C42) : Colors.white).withValues(
                    alpha: .72,
                  ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: accent.withValues(alpha: selected ? .55 : .12),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: .13),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      icon,
                      color: dark
                          ? Color.lerp(accent, Colors.white, .35)
                          : accent,
                      size: 23,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    selected
                        ? Icons.check_circle_rounded
                        : Icons.north_east_rounded,
                    color: accent.withValues(alpha: .8),
                    size: 17,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DesktopShell extends StatelessWidget {
  const _DesktopShell({required this.navigationShell, required this.strings});
  final StatefulNavigationShell navigationShell;
  final dynamic strings;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          _Sidebar(navigationShell: navigationShell, strings: strings),
          Expanded(child: navigationShell),
        ],
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.navigationShell, required this.strings});
  final StatefulNavigationShell navigationShell;
  final dynamic strings;

  @override
  Widget build(BuildContext context) {
    final collapsed = context.screenWidth < 1180;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: collapsed ? 88 : 264,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: dark
              ? [AppColors.glassDark, AppColors.bgDarkBottom]
              : [
                  Colors.white.withValues(alpha: .72),
                  Colors.white.withValues(alpha: .35),
                ],
        ),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: dark ? AppColors.glassDarkBorder : AppColors.glassLightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              mainAxisAlignment: collapsed
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              children: [
                const BrandMark(size: 36),
                if (!collapsed) ...[
                  const SizedBox(width: AppSpacing.md),
                  const Text(
                    'JUMA UI',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Expanded(
            child: ListView(
              children: [
                for (var i = 0; i < _allDestinations.length; i++)
                  _sidebarItem(context, i, collapsed),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sidebarItem(BuildContext context, int index, bool collapsed) {
    final destination = _allDestinations[index];
    final selected = navigationShell.currentIndex == index;
    final color = selected
        ? AppColors.skyDeep
        : Theme.of(context).colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 3,
      ),
      child: Material(
        color: selected
            ? AppColors.blue.withValues(alpha: 0.12)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: MotionInkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              mainAxisAlignment: collapsed
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              children: [
                Icon(destination.icon, size: 20, color: color),
                if (!collapsed) ...[
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      destination.labelBuilder(strings),
                      style: TextStyle(
                        color: color,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
