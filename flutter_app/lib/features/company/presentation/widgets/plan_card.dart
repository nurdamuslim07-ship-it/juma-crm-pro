import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../domain/entities/subscription_plan.dart';

/// Reusable plan card — Plan Cards requirement (START/PRO/BUSINESS/
/// ENTERPRISE), backed by `get_subscription_plans()`. `plan.priceTiyn
/// == null` renders as "contact sales" rather than a price, since
/// that's what a null price means for `enterprise` (see
/// SubscriptionPlan's own doc comment).
class PlanCard extends StatelessWidget {
  const PlanCard({
    super.key,
    required this.plan,
    required this.priceCustomLabel,
    required this.maxEmployeesLabel,
    required this.maxStorageLabel,
    required this.unlimitedLabel,
    required this.perMonthLabel,
    this.isCurrent = false,
    this.currentLabel,
  });

  final SubscriptionPlan plan;
  final String priceCustomLabel;
  final String maxEmployeesLabel;
  final String maxStorageLabel;
  final String unlimitedLabel;
  final String perMonthLabel;
  final bool isCurrent;
  final String? currentLabel;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  plan.nameKk,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              if (isCurrent && currentLabel != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    currentLabel!,
                    style: const TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            plan.priceTiyn == null
                ? priceCustomLabel
                : '${AppFormatters.tenge(plan.priceTiyn!)} $perMonthLabel',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: AppColors.skyDeep),
          ),
          const SizedBox(height: AppSpacing.lg),
          _limitRow(
            context,
            maxEmployeesLabel,
            plan.maxEmployees?.toString() ?? unlimitedLabel,
          ),
          _limitRow(
            context,
            maxStorageLabel,
            plan.maxStorageMb != null
                ? '${plan.maxStorageMb} MB'
                : unlimitedLabel,
          ),
          if (plan.features.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: plan.features.entries
                  .where((e) => e.value == true)
                  .map(
                    (e) => Chip(
                      label: Text(e.key),
                      visualDensity: VisualDensity.compact,
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _limitRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
