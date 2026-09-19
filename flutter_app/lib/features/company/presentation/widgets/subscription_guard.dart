import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/i18n/locale_provider.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/company_providers.dart';

/// Wraps a module screen (Orders/Warehouse/Production/Analytics/
/// Payments) and blocks it once the company's SUBSCRIPTION has
/// expired — distinct from `companies.is_active = false`, which the
/// router's own `resolveOnboardingRedirect()` already blocks the
/// WHOLE app for via AccessBlockedScreen. A lapsed plan is a softer
/// degradation: the tenant itself is still active, only certain
/// modules are hit.
///
/// This is UX convenience only, same status as the router's redirect
/// guard (see that guard's own doc comment) — no RLS policy in this
/// schema currently checks subscription status, so a determined client
/// could still call the underlying RPCs directly. Wiring real
/// enforcement into every affected module's RLS is future work (see
/// supabase/README.md's "Company Settings & Subscription Management"
/// section), not something this stage's ask required.
///
/// [allowDirectorBypass] is `true` only for the Payments route — a
/// director needs to see what's owed to actually renew; every other
/// wrapped module blocks for every role, director included.
class SubscriptionGuard extends ConsumerWidget {
  const SubscriptionGuard({
    super.key,
    required this.child,
    this.allowDirectorBypass = false,
  });

  final Widget child;
  final bool allowDirectorBypass;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final info = ref.watch(subscriptionInfoProvider).valueOrNull;
    // Fail open while loading/on error — this is a UX gate, not a
    // security boundary, so a transient network hiccup should never
    // lock a user out of a module they'd otherwise be allowed into.
    final blocked = info != null && info.isExpired && info.companyIsActive;
    if (!blocked) return child;

    final user = ref.watch(currentUserProvider);
    if (allowDirectorBypass && (user?.isDirector ?? false)) return child;

    return const _SubscriptionBlockedView();
  }
}

class _SubscriptionBlockedView extends ConsumerWidget {
  const _SubscriptionBlockedView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                LucideIcons.shieldAlert,
                size: 48,
                color: AppColors.warning,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                strings.subscriptionExpiredTitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                strings.subscriptionExpiredMessage,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (user?.isDirector ?? false) ...[
                const SizedBox(height: AppSpacing.xxl),
                AppButton(
                  label: strings.subscriptionExpiredRenewAction,
                  expand: false,
                  onPressed: () => context.push(RoutePaths.subscription),
                  icon: LucideIcons.creditCard,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
