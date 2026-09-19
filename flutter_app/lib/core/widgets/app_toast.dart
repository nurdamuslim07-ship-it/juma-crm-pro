import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';

enum ToastTone { info, success, error }

/// Global key so any layer (including Riverpod notifiers, outside the
/// widget tree) can surface a toast — replaces the web app's duplicated
/// `toastMessage` state + fixed-position div (once for mobile, once for
/// desktop, see COMPONENT_LIBRARY.md) with a single implementation.
final rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

abstract class AppToast {
  static void show(String message, {ToastTone tone = ToastTone.info}) {
    final messenger = rootScaffoldMessengerKey.currentState;
    if (messenger == null) return;
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: _bg(tone),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  static Color _bg(ToastTone tone) {
    switch (tone) {
      case ToastTone.success:
        return AppColors.success;
      case ToastTone.error:
        return AppColors.danger;
      case ToastTone.info:
        return AppColors.skyDeep;
    }
  }
}
