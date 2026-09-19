import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/i18n/locale_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../domain/entities/production_stage_history_entry.dart';

/// Requirement: "Өндіріс тарихы" — one row per real stage transition,
/// written only by the `enforce_production_stage_change` trigger (see
/// supabase/migrations/20260713000020_production_module.sql), never
/// directly by the app.
class ProductionHistorySection extends ConsumerWidget {
  const ProductionHistorySection({super.key, required this.history});

  final List<ProductionStageHistoryEntry> history;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final textTheme = Theme.of(context).textTheme;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(strings.productionHistoryTitle, style: textTheme.titleMedium),
          const SizedBox(height: AppSpacing.md),
          if (history.isEmpty)
            Text(strings.productionNoHistory, style: textTheme.bodyMedium)
          else
            for (final entry in history)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      LucideIcons.arrowRightCircle,
                      size: 16,
                      color: AppColors.textSecondaryLight,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.previousStageName != null
                                ? '${entry.previousStageName} → ${entry.newStageName}'
                                : entry.newStageName,
                            style: textTheme.bodyMedium,
                          ),
                          Text(
                            '${AppFormatters.dateTime(entry.changedAt)}'
                            '${entry.changedByName != null ? ' · ${entry.changedByName}' : ''}',
                            style: textTheme.bodySmall,
                          ),
                          if (entry.comment != null)
                            Text(entry.comment!, style: textTheme.bodySmall),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}
