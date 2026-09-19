import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/i18n/locale_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../domain/entities/partner.dart';
import 'partner_category_x.dart';

class PartnerListTile extends ConsumerWidget {
  const PartnerListTile({
    super.key,
    required this.partner,
    required this.onTap,
  });

  final Partner partner;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: GlassCard(
        onTap: onTap,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Opacity(
              opacity: partner.isActive ? 1 : 0.4,
              child: CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.skyDeep.withValues(alpha: 0.15),
                child: Icon(
                  partner.category.icon,
                  size: 20,
                  color: AppColors.skyDeep,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    partner.displayName,
                    style: textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    partner.category.label(strings),
                    style: textTheme.bodySmall,
                  ),
                  if (partner.phone != null)
                    Text(
                      partner.phone!,
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            if (!partner.isActive)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.textSecondaryLight.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  strings.partnerStatusInactive,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            else if (partner.isDeleted)
              Icon(
                LucideIcons.trash2,
                size: 16,
                color: AppColors.textSecondaryLight,
              ),
          ],
        ),
      ),
    );
  }
}
