import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'glass_card.dart';

enum StatTone { neutral, success, warning, danger }

/// `<StatCard>` primitive from COMPONENT_LIBRARY.md — replaces the
/// copy-pasted `<div className="border p-3.5 rounded-2xl ...">` KPI
/// tile markup repeated across the legacy web app's dashboard (mobile
/// and desktop trees) and ReportsModule.tsx.
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.tone = StatTone.neutral,
    this.onTap,
  });

  final String label;
  final String value;
  final IconData? icon;
  final StatTone tone;
  final VoidCallback? onTap;

  Color get _toneColor {
    switch (tone) {
      case StatTone.neutral:
        return AppColors.skyDeep;
      case StatTone.success:
        return AppColors.success;
      case StatTone.warning:
        return AppColors.warning;
      case StatTone.danger:
        return AppColors.danger;
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (icon != null) ...[
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: _toneColor.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(icon, size: 16, color: _toneColor),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  value,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(label, style: textTheme.bodySmall),
        ],
      ),
    );
  }
}
