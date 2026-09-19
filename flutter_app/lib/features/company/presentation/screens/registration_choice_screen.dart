import '../../../../core/widgets/press_motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/i18n/locale_provider.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/glass/liquid_glass.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../auth/presentation/widgets/auth_background.dart';

/// The first screen a signed-in user with no company sees — either a
/// brand-new signup, or one whose previous join request was rejected
/// (see `profiles.status = 'rejected'` — allowed to retry here, per
/// core/router/onboarding_redirect.dart). Reachable ONLY once signed
/// in (unlike SignUpScreen): the router redirect guard is what routes
/// here, not manual navigation.
class RegistrationChoiceScreen extends ConsumerWidget {
  const RegistrationChoiceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final user = ref.watch(currentUserProvider);
    final wasRejected = user?.status?.name == 'rejected';

    return AuthBackground(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: LiquidGlass(
              padding: const EdgeInsets.all(AppSpacing.xxxl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    strings.onboardingChoiceTitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    strings.onboardingChoiceSubtitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (wasRejected) ...[
                    const SizedBox(height: AppSpacing.lg),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            LucideIcons.alertTriangle,
                            color: AppColors.danger,
                            size: 20,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              strings.onboardingRejectedBanner,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xxl),
                  _ChoiceCard(
                    icon: LucideIcons.building2,
                    title: strings.onboardingCreateCompanyOption,
                    description: strings.onboardingCreateCompanyDescription,
                    onTap: () =>
                        context.push(RoutePaths.onboardingCreateCompany),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _ChoiceCard(
                    icon: LucideIcons.users,
                    title: strings.onboardingJoinCompanyOption,
                    description: strings.onboardingJoinCompanyDescription,
                    onTap: () => context.push(RoutePaths.onboardingJoinCompany),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  AppButton(
                    label: strings.authLogout,
                    variant: AppButtonVariant.ghost,
                    onPressed: () => ref.read(signOutUseCaseProvider).call(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MotionInkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.skyDeep.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.skyDeep.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.skyDeep.withValues(alpha: 0.15),
              child: Icon(icon, color: AppColors.skyDeep),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const Icon(LucideIcons.chevronRight, color: AppColors.skyDeep),
          ],
        ),
      ),
    );
  }
}
