import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/i18n/locale_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../auth/domain/entities/profile_status.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

/// Reached when `profiles.status = 'suspended'` (see
/// core/router/onboarding_redirect.dart — a value the current backend
/// never actually sets yet, see supabase/README.md's "Company
/// registration" section; this branch is forward-compatible scaffolding)
/// or when the owning `companies.is_active = false` (a real, already-
/// live signal — see that same README section). Either way there is
/// nothing to do here but explain and offer to sign out.
class AccessBlockedScreen extends ConsumerWidget {
  const AccessBlockedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final user = ref.watch(currentUserProvider);
    final isSuspended = user?.status == ProfileStatus.suspended;

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                LucideIcons.shieldAlert,
                size: 56,
                color: AppColors.danger,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                isSuspended
                    ? strings.accessBlockedSuspendedTitle
                    : strings.accessBlockedCompanyInactiveTitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                isSuspended
                    ? strings.accessBlockedSuspendedMessage
                    : strings.accessBlockedCompanyInactiveMessage,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.xxl),
              AppButton(
                label: strings.accessBlockedSignOutAction,
                variant: AppButtonVariant.secondary,
                expand: false,
                onPressed: () => ref.read(signOutUseCaseProvider).call(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
