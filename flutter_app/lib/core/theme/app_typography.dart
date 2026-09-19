import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Inter (UI text) + JetBrains Mono (numeric/price values), matching the
/// web app's font choice (src/index.css) so exported PDFs/screens feel
/// like the same product family. Kazakh Cyrillic glyph coverage is
/// verified for both families.
abstract class AppTypography {
  static TextTheme textTheme(Color primary, Color secondary) {
    final base = GoogleFonts.interTextTheme();
    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: primary,
      ),
      headlineLarge: base.headlineLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: primary,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: primary,
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontWeight: FontWeight.w600,
        color: primary,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: primary,
      ),
      bodyLarge: base.bodyLarge?.copyWith(color: primary),
      bodyMedium: base.bodyMedium?.copyWith(color: primary),
      bodySmall: base.bodySmall?.copyWith(color: secondary),
      labelLarge: base.labelLarge?.copyWith(
        fontWeight: FontWeight.w600,
        color: primary,
      ),
      labelMedium: base.labelMedium?.copyWith(color: secondary),
      labelSmall: base.labelSmall?.copyWith(color: secondary),
    );
  }

  /// Monospaced style for currency/measurement figures (₸ amounts, %s).
  static TextStyle numeric({
    required Color color,
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.w600,
  }) {
    return GoogleFonts.jetBrainsMono(
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
    );
  }
}
