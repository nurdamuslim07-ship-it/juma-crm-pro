import 'dart:ui';

import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../app_radius.dart';

/// iOS-26-style "Liquid Glass" frosted surface — the single visual
/// primitive every card/sheet/bar in the app builds on. Formalizes the
/// `.glass-moldyr-light/dark` classes from the web app's index.css
/// (see DESIGN_SYSTEM.md) as a reusable Flutter widget instead of
/// per-screen ad hoc BackdropFilter calls.
class LiquidGlass extends StatelessWidget {
  const LiquidGlass({
    super.key,
    required this.child,
    this.borderRadius,
    this.padding,
    this.blur = 28,
    this.opacity,
    this.border = true,
    this.elevated = true,
  });

  final Widget child;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final double blur;
  final double? opacity;
  final bool border;
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = borderRadius ?? BorderRadius.circular(AppRadius.card);
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final effectiveBlur = reduceMotion ? blur * 0.5 : blur;

    final fill = isDark
        ? AppColors.glassDark.withValues(alpha: opacity ?? 0.55)
        : AppColors.glassLight.withValues(alpha: opacity ?? 0.56);
    final borderColor = isDark
        ? AppColors.glassDarkBorder
        : AppColors.glassLightBorder;

    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: effectiveBlur, sigmaY: effectiveBlur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                fill,
                fill.withValues(alpha: (opacity ?? .56) * .65),
              ],
            ),
            borderRadius: radius,
            border: border ? Border.all(color: borderColor, width: 1) : null,
            boxShadow: elevated
                ? [
                    BoxShadow(
                      color: (isDark ? Colors.black : AppColors.skyDeep)
                          .withValues(alpha: isDark ? 0.35 : 0.06),
                      blurRadius: 32,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Floating glow orb used behind the login/dashboard backgrounds,
/// matching `.animate-float-orb` in the web app. Respects
/// `prefers-reduced-motion` (disabled animations), which the original
/// CSS keyframes did not (flagged as an accessibility gap in
/// DESIGN_SYSTEM.md — fixed here rather than carried over).
class FloatingOrb extends StatefulWidget {
  const FloatingOrb({
    super.key,
    required this.color,
    required this.size,
    this.reverse = false,
  });

  final Color color;
  final double size;
  final bool reverse;

  @override
  State<FloatingOrb> createState() => _FloatingOrbState();
}

class _FloatingOrbState extends State<FloatingOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final travel = reduceMotion ? 0.0 : (widget.reverse ? -18.0 : 18.0);

    Widget orb = Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            widget.color.withValues(alpha: .3),
            widget.color.withValues(alpha: 0),
          ],
        ),
      ),
    );

    if (reduceMotion) return orb;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_controller.value);
        return Transform.translate(offset: Offset(0, travel * t), child: child);
      },
      child: orb,
    );
  }
}
