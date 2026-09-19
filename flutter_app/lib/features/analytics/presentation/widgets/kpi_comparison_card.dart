import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/i18n/locale_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/stat_card.dart';
import '../../domain/analytics_period.dart';

/// [StatCard] plus a "Салыстыру: алдыңғы кезеңмен" delta badge.
/// [current]/[previous] null (either side unavailable/redacted) omits
/// the badge entirely; [previous] == 0 with a positive [current] shows
/// a "жаңа" ("new") badge instead of an undefined percentage, since
/// [computePeriodChangePercent] deliberately returns null for a
/// zero-previous baseline rather than an infinite/zero percentage.
class KpiComparisonCard extends ConsumerWidget {
  const KpiComparisonCard({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.tone = StatTone.neutral,
    this.current,
    this.previous,
    this.higherIsBetter = true,
  });

  final String label;
  final String value;
  final IconData? icon;
  final StatTone tone;
  final int? current;
  final int? previous;
  final bool higherIsBetter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final changePercent = computePeriodChangePercent(current, previous);
    final isNew = current != null && previous == 0 && current! > 0;

    return Stack(
      children: [
        StatCard(label: label, value: value, icon: icon, tone: tone),
        if (isNew)
          Positioned(
            top: AppSpacing.sm,
            right: AppSpacing.sm,
            child: _NewBadge(label: strings.analyticsPeriodComparisonNew),
          )
        else if (changePercent != null)
          Positioned(
            top: AppSpacing.sm,
            right: AppSpacing.sm,
            child: _DeltaBadge(
              changePercent: changePercent,
              higherIsBetter: higherIsBetter,
            ),
          ),
      ],
    );
  }
}

class _NewBadge extends StatelessWidget {
  const _NewBadge({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.success,
        ),
      ),
    );
  }
}

class _DeltaBadge extends StatelessWidget {
  const _DeltaBadge({
    required this.changePercent,
    required this.higherIsBetter,
  });

  final double changePercent;
  final bool higherIsBetter;

  @override
  Widget build(BuildContext context) {
    final isUp = changePercent > 0;
    final isGood = isUp == higherIsBetter;
    final color = changePercent == 0
        ? AppColors.textSecondaryLight
        : (isGood ? AppColors.success : AppColors.danger);

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isUp ? LucideIcons.trendingUp : LucideIcons.trendingDown,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 2),
          Text(
            '${changePercent.abs().toStringAsFixed(0)}%',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
