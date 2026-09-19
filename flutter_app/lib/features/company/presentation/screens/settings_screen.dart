import '../../../../core/widgets/app_back_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/i18n/locale_provider.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

/// The `/settings` tab's home screen — the app's "profile menu" (this
/// codebase has no separate avatar-dropdown widget; the Settings tab
/// is where account/company-level entries live). Replaces the
/// `ComingSoonScreen` stub this tab used before Stage 3.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: Text(strings.navSettings),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          if (user != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: Text(
                user.fullName,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          _MenuTile(
            icon: LucideIcons.building2,
            label: strings.settingsMenuCompany,
            onTap: () => context.push(RoutePaths.companySettings),
          ),
          _MenuTile(
            icon: LucideIcons.creditCard,
            label: strings.settingsMenuSubscription,
            onTap: () => context.push(RoutePaths.subscription),
          ),
          _MenuTile(
            icon: LucideIcons.receipt,
            label: strings.settingsMenuBilling,
            onTap: () => context.push(RoutePaths.billing),
          ),
          if (user?.isDirector ?? false)
            _MenuTile(
              icon: LucideIcons.fileText,
              label: strings.settingsMenuAuditLog,
              onTap: () => context.push(RoutePaths.auditLog),
            ),
          const SizedBox(height: AppSpacing.xl),
          _MenuTile(
            icon: LucideIcons.logOut,
            label: strings.authLogout,
            onTap: () => ref.read(signOutUseCaseProvider).call(),
          ),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: AppColors.skyDeep.withValues(alpha: 0.15),
        child: Icon(icon, color: AppColors.skyDeep, size: 20),
      ),
      title: Text(label, style: Theme.of(context).textTheme.bodyLarge),
      trailing: const Icon(LucideIcons.chevronRight, size: 18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }
}
