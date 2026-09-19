import '../../../../core/widgets/app_back_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/i18n/locale_provider.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/state_views.dart';
import '../providers/company_providers.dart';

/// No real payment/invoicing integration exists yet (see
/// supabase/README.md — every price in `subscription_plans` is a
/// placeholder). This screen is deliberately honest about that: it
/// shows the current plan/renewal date (reusing
/// `get_company_subscription_info()`, no new backend surface) and
/// links to the Subscription screen, rather than fabricating a fake
/// invoice history.
class BillingScreen extends ConsumerWidget {
  const BillingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final infoAsync = ref.watch(subscriptionInfoProvider);

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: Text(strings.billingTitle),
      ),
      body: infoAsync.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorView(
          message: strings.commonError,
          retryLabel: strings.commonRetry,
          onRetry: () => ref.invalidate(subscriptionInfoProvider),
        ),
        data: (info) {
          final dateFormat = DateFormat('dd.MM.yyyy');
          return Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                EmptyView(
                  icon: LucideIcons.receipt,
                  title: strings.billingNoHistoryTitle,
                  description: info.priceTiyn != null
                      ? '${strings.billingNextChargeLabel}: '
                            '${AppFormatters.tenge(info.priceTiyn!)} '
                            '(${info.expiresAt != null ? dateFormat.format(info.expiresAt!) : '—'})'
                      : strings.billingContactSalesDescription,
                ),
                const SizedBox(height: AppSpacing.lg),
                AppButton(
                  label: strings.settingsMenuSubscription,
                  variant: AppButtonVariant.secondary,
                  onPressed: () => context.push(RoutePaths.subscription),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
