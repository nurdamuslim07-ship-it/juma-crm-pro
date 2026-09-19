import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:juma_ui_crm/core/theme/app_theme.dart';
import 'package:juma_ui_crm/features/quick_estimate/estimate_screen.dart';
import 'package:juma_ui_crm/features/quick_estimate/estimate_repository.dart';
import 'package:juma_ui_crm/features/quick_estimate/estimate_model.dart';

class FakeRepo extends EstimateRepository {
  FakeRepo()
    : super(
        SupabaseClient(
          'https://test.supabase.co',
          'test',
          authOptions: const AuthClientOptions(autoRefreshToken: false),
        ),
      );
  @override
  Future<List<CostLine>> catalog() async => [];
  @override
  Future<String> save(String? id, Estimate e) async => 'saved';
}

void main() {
  for (final width in [320.0, 402.0, 1024.0]) {
    testWidgets('calculator fits $width with keyboard and live summary', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 800);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repo = FakeRepo();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [estimateRepositoryProvider.overrideWithValue(repo)],
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const EstimateEditor(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Толық емес:'), findsOneWidget);
      expect(find.textContaining('Клиентке:'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.enterText(find.byType(TextFormField).first, 'Асүй тест');
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      tester.view.resetViewInsets();
    });
  }
}
