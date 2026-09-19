import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:juma_ui_crm/core/connectivity/connectivity_provider.dart';
import 'package:juma_ui_crm/core/widgets/offline_banner.dart';

Future<void> _pump(WidgetTester tester, {required bool online}) {
  return tester.pumpWidget(
    ProviderScope(
      overrides: [
        connectivityProvider.overrideWith((ref) => Stream.value(online)),
      ],
      child: const MaterialApp(home: Scaffold(body: OfflineBanner())),
    ),
  );
}

const _offlineMessage =
    'Байланыс жоқ. Деректер соңғы белгілі күйде көрсетілуде';

void main() {
  testWidgets('renders nothing while online', (tester) async {
    await _pump(tester, online: true);
    await tester.pump();

    expect(find.text(_offlineMessage), findsNothing);
    expect(find.byType(SizedBox), findsWidgets);
  });

  testWidgets('shows the offline message while offline', (tester) async {
    await _pump(tester, online: false);
    await tester.pump();

    expect(find.text(_offlineMessage), findsOneWidget);
  });
}
