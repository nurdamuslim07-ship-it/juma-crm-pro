import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/i18n/locale_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../domain/entities/top_client.dart';

/// Requirement: "Ең көп тапсырыс беретін клиенттер" — director/manager
/// only (`get_top_clients()` returns an empty list for anyone else, so
/// this section simply doesn't render for them — see the screen).
class TopClientsSection extends ConsumerWidget {
  const TopClientsSection({super.key, required this.clients});

  final List<TopClient> clients;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings.analyticsTopClientsTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          if (clients.isEmpty)
            Text(
              strings.analyticsNoDataForPeriod,
              style: Theme.of(context).textTheme.bodyMedium,
            )
          else
            for (var i = 0; i < clients.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: AppColors.skyDeep.withValues(
                        alpha: 0.15,
                      ),
                      child: Text(
                        '${i + 1}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
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
                            clients[i].clientName,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          Text(
                            '${clients[i].ordersCount} '
                            '${strings.analyticsOrdersCountSuffix}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      AppFormatters.tenge(clients[i].totalAmountTiyn),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700,
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
