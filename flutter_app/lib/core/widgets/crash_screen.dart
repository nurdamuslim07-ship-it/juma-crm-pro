import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Installed as `ErrorWidget.builder` in `main.dart` — the fallback
/// for any uncaught build/render error, replacing Flutter's default
/// red/grey error box. Deliberately minimal and self-contained (a
/// `Material` wrapper, not a `Scaffold`): `ErrorWidget.builder` can
/// replace a broken widget anywhere in the tree, not just a full
/// screen, so this must render correctly however small the space it's
/// given. The message is a hardcoded Kazakh literal rather than
/// routed through `AppStrings`/Riverpod — this builder can fire
/// before/outside any `ProviderScope` ancestor is guaranteed to be
/// reachable, the same reasoning `PermissionFailure`'s default
/// message in `core/error/failures.dart` already uses.
class CrashScreen extends StatelessWidget {
  const CrashScreen({super.key, required this.details});

  final FlutterErrorDetails details;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.redAccent,
                size: 40,
              ),
              const SizedBox(height: 12),
              const Text(
                'Күтпеген қате орын алды',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              if (kDebugMode) ...[
                const SizedBox(height: 8),
                Text(
                  details.exceptionAsString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 11, color: Colors.black54),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
