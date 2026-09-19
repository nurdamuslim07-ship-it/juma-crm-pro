import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:juma_ui_crm/core/theme/app_theme.dart';
import 'package:juma_ui_crm/features/auth/domain/entities/auth_user.dart';
import 'package:juma_ui_crm/features/auth/presentation/providers/auth_providers.dart';
import 'package:juma_ui_crm/features/auth/presentation/screens/login_screen.dart';
import 'package:juma_ui_crm/features/dashboard/domain/entities/dashboard_summary.dart';
import 'package:juma_ui_crm/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:juma_ui_crm/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:juma_ui_crm/features/notifications/presentation/providers/notification_providers.dart';

void main() {
  for (final size in [
    const Size(320, 640),
    const Size(402, 874),
    const Size(768, 1024),
    const Size(1024, 768),
  ]) {
    testWidgets('Dashboard fits $size including all KPI cards', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWithValue(
              const AuthUser(
                id: 'test',
                fullName: 'Жергілікті әзірлеуші',
                isActive: true,
                roleKeys: ['owner'],
              ),
            ),
            unreadNotificationCountProvider.overrideWithValue(0),
            dashboardSummaryProvider.overrideWith(
              (ref) async => const DashboardSummary(
                activeOrdersCount: 3,
                delayedOrdersCount: 1,
                completedThisMonthCount: 2,
                totalContractAmountTiyn: 120000000,
                paymentsReceivedTiyn: 70000000,
                expensesTiyn: 500000,
                lowStockMaterialsCount: 2,
                upcomingDeliveriesCount: 1,
                myOpenTasksCount: 3,
                myTodayTasksCount: 2,
              ),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const DashboardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.drag(find.byType(ListView), const Offset(0, -1200));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
    testWidgets('Login fits $size with keyboard open', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const LoginScreen(),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
