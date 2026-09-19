import 'package:flutter/foundation.dart';

/// Local development only. Never creates a session or grants roles.
bool canSkipDevelopmentContactVerification({
  required bool debugBuild,
  required bool enabled,
  required bool localWeb,
  required String allowedUserId,
  required String? userId,
}) =>
    debugBuild &&
    enabled &&
    localWeb &&
    allowedUserId.isNotEmpty &&
    userId == allowedUserId;

bool skipDevelopmentContactVerification(String? userId) =>
    canSkipDevelopmentContactVerification(
      debugBuild: kDebugMode,
      enabled: const bool.fromEnvironment('LOCAL_DEVELOPMENT_ACCESS'),
      localWeb:
          kIsWeb &&
          const {'localhost', '127.0.0.1', '::1'}.contains(Uri.base.host),
      allowedUserId: const String.fromEnvironment('DEVELOPMENT_USER_ID'),
      userId: userId,
    );
