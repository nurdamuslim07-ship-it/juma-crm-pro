import 'press_motion.dart';
import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/glass/liquid_glass.dart';

/// Default-padded [LiquidGlass] surface for content cards (dashboard
/// tiles, list items, form panels) — see COMPONENT_LIBRARY.md `<GlassCard>`.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final glass = LiquidGlass(padding: padding, child: child);
    if (onTap == null) return glass;
    return MotionInkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: glass,
    );
  }
}
