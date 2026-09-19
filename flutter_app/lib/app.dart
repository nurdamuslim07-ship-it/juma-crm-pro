import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/backend_status.dart';
import 'core/providers/backend_status_provider.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_mode_provider.dart';
import 'core/theme/glass/glass_background.dart';
import 'core/widgets/app_toast.dart';
import 'core/widgets/configuration_error_screen.dart';
import 'core/widgets/demo_preview_screen.dart';

class JumaUiApp extends ConsumerWidget {
  const JumaUiApp({super.key});

  static const _localizationDelegates = [
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];
  static const _supportedLocales = [Locale('kk', 'KZ'), Locale('ru', 'RU')];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(backendStatusProvider);

    // Guard clause: while status != ready, routerProvider (and every
    // provider it pulls in, including supabaseClientProvider and the
    // GoRouter redirect callback's direct Supabase.instance.client
    // read) is never watched or constructed — this is what actually
    // fixes "You must initialize the supabase instance before calling
    // Supabase.instance": the router/provider tree that touches it
    // simply doesn't exist yet on this branch.
    if (status != BackendStatus.ready) {
      final demoMode = ref.watch(demoModeProvider);
      return MaterialApp(
        title: 'JUMA UI',
        debugShowCheckedModeBanner: false,
        scaffoldMessengerKey: rootScaffoldMessengerKey,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ref.watch(themeModeProvider),
        builder: (context, child) => GlassBackground(child: child!),
        locale: const Locale('kk', 'KZ'),
        supportedLocales: _supportedLocales,
        localizationsDelegates: _localizationDelegates,
        home: demoMode
            ? DemoPreviewScreen(
                onBack: () => ref.read(demoModeProvider.notifier).state = false,
              )
            : ConfigurationErrorScreen(
                status: status,
                onOpenDemoMode: () =>
                    ref.read(demoModeProvider.notifier).state = true,
              ),
      );
    }

    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'JUMA UI',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ref.watch(themeModeProvider),
      builder: (context, child) => GlassBackground(child: child!),
      routerConfig: router,
      // Kazakh-first: the app never auto-detects device language and
      // always defaults to kk regardless of system locale (see
      // KAZAKH_LOCALIZATION.md) — this only controls Flutter's own
      // built-in widgets (date pickers, etc.), not app UI strings,
      // which flow through core/i18n/app_strings.dart instead.
      locale: const Locale('kk', 'KZ'),
      supportedLocales: _supportedLocales,
      localizationsDelegates: _localizationDelegates,
    );
  }
}
