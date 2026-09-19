import 'package:flutter/material.dart';

/// Light-blue "Liquid Glass" palette, carried over 1:1 from the existing
/// web app's `.glass-moldyr-light/dark` design language (see
/// DESIGN_SYSTEM.md) so the visual identity stays consistent across
/// platforms rather than being redesigned for Flutter.
abstract class AppColors {
  // Brand gradient anchors (sky → indigo → teal), matching the web login
  // background and primary CTA gradients.
  static const skySoft = Color(0xFFE0F2FE); // sky-100
  static const sky = Color(0xFF7DD3FC); // sky-300
  static const skyDeep = Color(0xFF168EF1); // sky-500
  static const blue = Color(0xFF2EA7FF); // blue-600
  static const indigo = Color(0xFF5A78FF); // indigo-600
  static const teal = Color(0xFF14B8A6); // teal-500

  // Glass surfaces — rgba values match src/index.css .glass-moldyr-*.
  static const glassLight = Color(0x99FFFFFF); // rgba(224,242,254,0.6)
  static const glassLightBorder = Color(0xC7FFFFFF); // rgba(255,255,255,0.65)
  static const glassDark = Color(0x8C142846); // rgba(15,23,42,0.55)
  static const glassDarkBorder = Color(0x29FFFFFF); // rgba(56,189,248,0.15)

  // Backgrounds
  static const bgLightTop = Color(0xFFF8FDFF); // sky-200
  static const bgLightMid = Color(0xFFEAF7FF); // sky-50
  static const bgLightBottom = Color(0xFFF9FCFF); // blue-200
  static const bgDarkTop = Color(0xFF0B1728); // slate-950
  static const bgDarkMid = Color(0xFF0C1D3D); // slate-900
  static const bgDarkBottom = Color(0xFF122947); // sky-950

  // Semantic
  static const success = Color(0xFF16A34A);
  static const warning = Color(0xFFF59E0B);
  static const danger = Color(0xFFDC2626);

  // Text
  static const textPrimaryLight = Color(0xFF0C1D3D);
  static const textSecondaryLight = Color(0xFF6D7D98);
  static const textPrimaryDark = Color(0xFFF8FAFC);
  static const textSecondaryDark = Color(0xFFA8B8D3);

  static const primaryGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF2AB5FF), Color(0xFF4D7DFF)],
  );

  static const primaryGradientDark = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF2AB5FF), Color(0xFF4D7DFF)],
  );

  static const brandLogoGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF71D3FF), Color(0xFF2F8DFF), Color(0xFF5E74FF)],
  );
}
