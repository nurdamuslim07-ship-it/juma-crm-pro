import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/config/backend_status.dart';
import 'core/config/env.dart';
import 'core/providers/backend_status_provider.dart';
import 'core/widgets/crash_screen.dart';

Future<void> main() async {
  // No crash-reporting SDK is wired into this project yet (found
  // during the production audit) — this at minimum stops an uncaught
  // exception from either silently vanishing (PlatformDispatcher path)
  // or showing Flutter's default red/grey error box with no recovery
  // action, and logs it via debugPrint so it's still visible in
  // `flutter run`/device logs even without a reporting backend.
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint(
      'FlutterError: ${details.exceptionAsString()}\n${details.stack}',
    );
  };
  ErrorWidget.builder = (details) => CrashScreen(details: details);
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Uncaught PlatformDispatcher error: $error\n$stack');
    return true;
  };

  runZonedGuarded(() async {
    // Must run before anything touches plugins (dotenv's asset load,
    // Supabase's platform channels) — on every platform including web.
    WidgetsFlutterBinding.ensureInitialized();

    // .env is gitignored; a fresh checkout only has the placeholder
    // values from .env.example until a real Supabase project is wired
    // up (see supabase/README.md). Loading it never throws by itself —
    // dotenv just yields empty values if the file is missing keys.
    await dotenv.load(fileName: '.env');

    final status = await _initializeBackend();

    // `status` is resolved here, before runApp(), and handed down as a
    // Riverpod override — nothing below this point (routerProvider,
    // supabaseClientProvider, GoRouter's own redirect callback) is ever
    // constructed or reads Supabase.instance while status is anything
    // other than BackendStatus.ready (see app.dart's branch on it).
    runApp(
      ProviderScope(
        overrides: [backendStatusProvider.overrideWithValue(status)],
        child: const JumaUiApp(),
      ),
    );
  }, (error, stack) => debugPrint('Uncaught zone error: $error\n$stack'));
}

Future<BackendStatus> _initializeBackend() async {
  if (!Env.isConfigured) return BackendStatus.notConfigured;

  try {
    await Supabase.initialize(
      url: Env.supabaseUrl,
      publishableKey: Env.supabaseAnonKey,
    );
    return BackendStatus.ready;
  } catch (_) {
    // Values were present but Supabase.initialize() itself rejected
    // them (malformed URL, etc.) — surface the same Kazakh
    // configuration screen rather than an uncaught crash.
    return BackendStatus.initFailed;
  }
}
