import 'press_motion.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

enum AppButtonVariant { primary, secondary, destructive, ghost }

/// The single reusable button primitive (see COMPONENT_LIBRARY.md) —
/// replaces the ad hoc `bg-gradient-to-r from-blue-600 to-indigo-600 ...`
/// literals repeated across every CTA in the web app.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.loading = false,
    this.icon,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool loading;
  final IconData? icon;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final disabled = onPressed == null || loading;

    Widget content = loading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              color: _foreground(variant, isDark),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: _foreground(variant, isDark)),
                const SizedBox(width: AppSpacing.sm),
              ],
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _foreground(variant, isDark),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          );

    final button = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      constraints: const BoxConstraints(
        minHeight: AppSpacing.minTouchTarget + 8,
      ),
      width: expand ? double.infinity : null,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        gradient: variant == AppButtonVariant.primary
            ? (isDark
                  ? AppColors.primaryGradientDark
                  : AppColors.primaryGradient)
            : null,
        color: _background(variant, isDark, disabled),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: variant == AppButtonVariant.primary && !disabled
            ? [
                BoxShadow(
                  color: AppColors.blue.withValues(alpha: .22),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ]
            : null,
        border: variant == AppButtonVariant.secondary
            ? Border.all(
                color: isDark
                    ? AppColors.glassDarkBorder
                    : AppColors.glassLightBorder,
              )
            : null,
      ),
      alignment: Alignment.center,
      child: content,
    );

    return Opacity(
      opacity: disabled && !loading ? 0.5 : 1,
      child: Material(
        color: Colors.transparent,
        child: MotionInkWell(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          onTap: disabled ? null : onPressed,
          child: button,
        ),
      ),
    );
  }

  Color? _background(AppButtonVariant v, bool isDark, bool disabled) {
    switch (v) {
      case AppButtonVariant.primary:
        return null; // gradient handles it
      case AppButtonVariant.secondary:
        return Colors.transparent;
      case AppButtonVariant.destructive:
        return AppColors.danger.withValues(alpha: 0.12);
      case AppButtonVariant.ghost:
        return Colors.transparent;
    }
  }

  Color _foreground(AppButtonVariant v, bool isDark) {
    switch (v) {
      case AppButtonVariant.primary:
        return Colors.white;
      case AppButtonVariant.secondary:
        return isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
      case AppButtonVariant.destructive:
        return AppColors.danger;
      case AppButtonVariant.ghost:
        return isDark ? AppColors.sky : AppColors.skyDeep;
    }
  }
}
