import 'package:flutter/material.dart';

/// Breakpoints matching RESPONSIVE_LAYOUT.md (Tailwind's default scale,
/// carried over so the Flutter and web docs describe the same device
/// matrix): sm 640, md 768, lg 1024, xl 1280, 2xl 1536.
///
/// Unlike the audited web app's `isMobileViewport` JS-resize-listener
/// branch (two duplicated full JSX trees), this is deliberately a pure
/// function of `MediaQuery` width used to pick *chrome only* — see
/// `core/widgets/app_shell.dart` — never to duplicate page content.
enum DeviceClass { mobile, tablet, desktop }

abstract class Breakpoints {
  static const double sm = 640;
  static const double md = 768;
  static const double lg = 1024;
  static const double xl = 1280;
  static const double xxl = 1536;
}

extension ResponsiveContext on BuildContext {
  double get screenWidth => MediaQuery.sizeOf(this).width;

  DeviceClass get deviceClass {
    final w = screenWidth;
    if (w >= Breakpoints.lg) return DeviceClass.desktop;
    if (w >= Breakpoints.md) return DeviceClass.tablet;
    return DeviceClass.mobile;
  }

  bool get isMobile => deviceClass == DeviceClass.mobile;
  bool get isTablet => deviceClass == DeviceClass.tablet;
  bool get isDesktop => deviceClass == DeviceClass.desktop;

  /// Tablet gets 2 dashboard columns, desktop gets more, per
  /// RESPONSIVE_LAYOUT.md's tablet-specific behavior requirement.
  int get dashboardColumns {
    switch (deviceClass) {
      case DeviceClass.mobile:
        return 2;
      case DeviceClass.tablet:
        return 2;
      case DeviceClass.desktop:
        return screenWidth >= Breakpoints.xl ? 4 : 3;
    }
  }

  EdgeInsets get pageInsets {
    switch (deviceClass) {
      case DeviceClass.mobile:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 12);
      case DeviceClass.tablet:
        return const EdgeInsets.symmetric(horizontal: 28, vertical: 20);
      case DeviceClass.desktop:
        return const EdgeInsets.symmetric(horizontal: 40, vertical: 24);
    }
  }
}
