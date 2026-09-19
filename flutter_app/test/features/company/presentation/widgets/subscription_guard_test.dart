import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:juma_ui_crm/features/auth/domain/entities/auth_user.dart';
import 'package:juma_ui_crm/features/auth/presentation/providers/auth_providers.dart';
import 'package:juma_ui_crm/features/company/domain/entities/company_subscription_info.dart';
import 'package:juma_ui_crm/features/company/presentation/providers/company_providers.dart';
import 'package:juma_ui_crm/features/company/presentation/widgets/subscription_guard.dart';

const _director = AuthUser(
  id: 'director-1',
  fullName: 'Director',
  isActive: true,
  roleKeys: ['director'],
);

const _manager = AuthUser(
  id: 'manager-1',
  fullName: 'Manager',
  isActive: true,
  roleKeys: ['manager'],
);

CompanySubscriptionInfo _info({required bool expired}) {
  return CompanySubscriptionInfo(
    planKey: 'pro',
    planNameKk: 'Про',
    status: expired ? 'expired' : 'active',
    startedAt: DateTime(2026, 1, 1),
    remainingDays: expired ? 0 : 20,
    isTrial: false,
    companyIsActive: true,
    activeUsers: 3,
  );
}

Future<void> _pump(
  WidgetTester tester, {
  required CompanySubscriptionInfo info,
  required AuthUser user,
  bool allowDirectorBypass = false,
}) {
  return tester.pumpWidget(
    ProviderScope(
      overrides: [
        subscriptionInfoProvider.overrideWith((ref) => Future.value(info)),
        currentUserProvider.overrideWithValue(user),
      ],
      child: MaterialApp(
        home: SubscriptionGuard(
          allowDirectorBypass: allowDirectorBypass,
          child: const Text('module content'),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('renders the wrapped module when the subscription is active', (
    tester,
  ) async {
    await _pump(tester, info: _info(expired: false), user: _manager);
    await tester.pumpAndSettle();

    expect(find.text('module content'), findsOneWidget);
  });

  testWidgets('blocks a non-director when the subscription has expired', (
    tester,
  ) async {
    await _pump(tester, info: _info(expired: true), user: _manager);
    await tester.pumpAndSettle();

    expect(find.text('module content'), findsNothing);
  });

  testWidgets(
    'still blocks a director when allowDirectorBypass is false (default)',
    (tester) async {
      await _pump(tester, info: _info(expired: true), user: _director);
      await tester.pumpAndSettle();

      expect(find.text('module content'), findsNothing);
    },
  );

  testWidgets(
    'lets a director through when allowDirectorBypass is true (Payments)',
    (tester) async {
      await _pump(
        tester,
        info: _info(expired: true),
        user: _director,
        allowDirectorBypass: true,
      );
      await tester.pumpAndSettle();

      expect(find.text('module content'), findsOneWidget);
    },
  );

  testWidgets(
    'still blocks a non-director even when allowDirectorBypass is true',
    (tester) async {
      await _pump(
        tester,
        info: _info(expired: true),
        user: _manager,
        allowDirectorBypass: true,
      );
      await tester.pumpAndSettle();

      expect(find.text('module content'), findsNothing);
    },
  );
}
