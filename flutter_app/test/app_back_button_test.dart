import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:juma_ui_crm/core/widgets/app_back_button.dart';

void main() {
  testWidgets('back pops detail then returns section root to dashboard', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/orders',
      routes: [
        GoRoute(
          path: '/dashboard',
          builder: (_, _) => const Scaffold(body: Text('Home')),
        ),
        GoRoute(
          path: '/orders',
          builder: (_, _) => Scaffold(
            appBar: AppBar(leading: const AppBackButton()),
            body: const Text('Orders'),
          ),
          routes: [
            GoRoute(
              path: 'detail',
              builder: (_, _) => Scaffold(
                appBar: AppBar(leading: const AppBackButton()),
                body: const Text('Detail'),
              ),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    router.push('/orders/detail');
    await tester.pumpAndSettle();
    await tester.tap(find.byType(AppBackButton).last);
    await tester.pumpAndSettle();
    expect(find.text('Orders'), findsOneWidget);
    await tester.tap(find.byType(AppBackButton));
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsOneWidget);
  });
}
