import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:juma_ui_crm/core/theme/app_theme.dart';
import 'package:juma_ui_crm/features/order_workflow/order_workflow_screen.dart';
import 'package:juma_ui_crm/features/order_workflow/workflow_repository.dart';
import 'package:juma_ui_crm/features/order_workflow/workflow_strings.dart';
import 'package:juma_ui_crm/features/order_workflow/contract_editor.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final order = <String, dynamic>{
    'id': 'order',
    'company_id': 'company',
    'client_id': 'client',
    'order_number': 'TEST-1',
    'journey_stage': 'cutting',
    'product_type': 'Асүй',
    'total_amount_tiyn': 28000000,
    'client': {'name': 'Тест клиенті', 'phone': '+77000000000'},
  };
  for (final size in [const Size(320, 700), const Size(768, 1024)]) {
    testWidgets('workflow and queue fit $size', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            orderWorkflowProvider('order').overrideWith(
              (ref) async => {
                'order': order,
                'history': [
                  {'stage': 'cutting', 'created_at': '2026-09-19T10:00:00Z'},
                ],
                'messages': [
                  {
                    'kind': 'stage',
                    'payload': {'stage': 'cutting'},
                    'status': 'queued',
                    'created_at': '2026-09-19T10:00:00Z',
                  },
                ],
                'contracts': [],
                'consent': [],
                'company': [],
              },
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const OrderWorkflowScreen(orderId: 'order'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Кесу'), findsWidgets);
      expect(tester.takeException(), isNull);
      await tester.drag(find.byType(ListView), const Offset(0, -700));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
    testWidgets('contract cannot save missing terms at $size', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.light(),
            home: ContractEditor(
              order: order,
              company: const {'name': 'Тест компаниясы'},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Сақтау'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Сақтау'));
      await tester.pumpAndSettle();
      expect(find.text('Өрісті толтырыңыз'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  }
  test(
    'contract PDF contains valid document with Kazakh draft labels',
    () async {
      final bytes = await contractPdf(
        {
          'Орындаушы': 'Тест компаниясы',
          'Құны': '280000 ₸',
          'Кепілдік': 'Келісуге арналған жоба',
        },
        const WorkflowStrings(false),
        'TEST-1',
      );
      expect(ascii.decode(bytes.take(4).toList()), '%PDF');
      expect(bytes.length, greaterThan(1000));
    },
  );
}
