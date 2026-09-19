import 'form_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import '../widgets/press_motion.dart';
import 'app_radius.dart';
import 'app_typography.dart';

/// Light/dark ThemeData built from the token files in this folder.
/// Non-goal (see DESIGN_SYSTEM.md): this is not a redesign — every value
/// here mirrors the existing web app's glassmorphism identity.
abstract class AppTheme {
  static ThemeData light() {
    final textTheme = AppTypography.textTheme(
      AppColors.textPrimaryLight,
      AppColors.textSecondaryLight,
    );
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.blue,
      brightness: Brightness.light,
      primary: AppColors.blue,
      secondary: AppColors.teal,
      error: AppColors.danger,
      surface: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      filledButtonTheme: const FilledButtonThemeData(
        style: ButtonStyle(
          backgroundBuilder: buttonMotion,
          animationDuration: Duration(milliseconds: 220),
        ),
      ),
      outlinedButtonTheme: const OutlinedButtonThemeData(
        style: ButtonStyle(
          backgroundBuilder: buttonMotion,
          animationDuration: Duration(milliseconds: 220),
        ),
      ),
      textButtonTheme: const TextButtonThemeData(
        style: ButtonStyle(
          backgroundBuilder: buttonMotion,
          animationDuration: Duration(milliseconds: 220),
        ),
      ),
      iconButtonTheme: const IconButtonThemeData(
        style: ButtonStyle(
          backgroundBuilder: buttonMotion,
          animationDuration: Duration(milliseconds: 220),
        ),
      ),
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: Colors.transparent,
      textTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
        iconTheme: IconThemeData(color: AppColors.textPrimaryLight),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white.withValues(alpha: 0.7),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style:
            ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              textStyle: textTheme.labelLarge,
            ).copyWith(
              backgroundBuilder: buttonMotion,
              animationDuration: const Duration(milliseconds: 220),
            ),
      ),
      inputDecorationTheme: FormStyle.inputs(false),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.textSecondaryLight.withValues(alpha: 0.12),
      ),
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }

  static ThemeData dark() {
    final textTheme = AppTypography.textTheme(
      AppColors.textPrimaryDark,
      AppColors.textSecondaryDark,
    );
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.teal,
      brightness: Brightness.dark,
      primary: AppColors.teal,
      secondary: AppColors.indigo,
      error: AppColors.danger,
      surface: AppColors.bgDarkMid,
    );

    return ThemeData(
      useMaterial3: true,
      filledButtonTheme: const FilledButtonThemeData(
        style: ButtonStyle(
          backgroundBuilder: buttonMotion,
          animationDuration: Duration(milliseconds: 220),
        ),
      ),
      outlinedButtonTheme: const OutlinedButtonThemeData(
        style: ButtonStyle(
          backgroundBuilder: buttonMotion,
          animationDuration: Duration(milliseconds: 220),
        ),
      ),
      textButtonTheme: const TextButtonThemeData(
        style: ButtonStyle(
          backgroundBuilder: buttonMotion,
          animationDuration: Duration(milliseconds: 220),
        ),
      ),
      iconButtonTheme: const IconButtonThemeData(
        style: ButtonStyle(
          backgroundBuilder: buttonMotion,
          animationDuration: Duration(milliseconds: 220),
        ),
      ),
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: Colors.transparent,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        systemOverlayStyle: SystemUiOverlayStyle.light,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
        iconTheme: IconThemeData(color: AppColors.textPrimaryDark),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.bgDarkTop.withValues(alpha: 0.6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style:
            ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              textStyle: textTheme.labelLarge,
            ).copyWith(
              backgroundBuilder: buttonMotion,
              animationDuration: const Duration(milliseconds: 220),
            ),
      ),
      inputDecorationTheme: FormStyle.inputs(true),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.textSecondaryDark.withValues(alpha: 0.12),
      ),
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }
}
