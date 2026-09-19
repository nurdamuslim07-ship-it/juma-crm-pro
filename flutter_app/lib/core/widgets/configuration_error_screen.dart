import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../config/backend_status.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/glass/liquid_glass.dart';
import 'app_button.dart';

/// Shown instead of the real app whenever `main()` could not bring up
/// Supabase — either `.env` still has the `.env.example` placeholder
/// values, or `Supabase.initialize()` itself rejected them. This is
/// the graceful path requested for the "must initialize the supabase
/// instance" crash: a clear Kazakh explanation instead of a red error
/// screen, with a way to preview the UI without a backend.
class ConfigurationErrorScreen extends StatelessWidget {
  const ConfigurationErrorScreen({
    super.key,
    required this.status,
    required this.onOpenDemoMode,
  });

  final BackendStatus status;
  final VoidCallback onOpenDemoMode;

  @override
  Widget build(BuildContext context) {
    final title = status == BackendStatus.initFailed
        ? 'Supabase-ге қосылу мүмкін болмады'
        : 'Supabase бапталмаған';

    final body = status == BackendStatus.initFailed
        ? 'flutter_app/.env файлындағы SUPABASE_URL немесе '
              'SUPABASE_ANON_KEY мәні жарамсыз болып тұр. Мәндерді '
              'Supabase жобаңыздың Settings → API бетінен қайта көшіріп, '
              'қолданбаны қайта іске қосыңыз.'
        : 'flutter_app/.env файлында SUPABASE_URL және SUPABASE_ANON_KEY '
              'әлі толтырылмаған (әдепкі бойынша .env.example-дегі үлгі '
              'мәндер тұр). Нақты Supabase жобаңыздың мәндерін енгізіп, '
              'қолданбаны қайта іске қосыңыз — толық нұсқаулық '
              'supabase/README.md файлында.';

    return Scaffold(
      backgroundColor: AppColors.bgLightMid,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: LiquidGlass(
                padding: const EdgeInsets.all(AppSpacing.xxxl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          LucideIcons.serverCrash,
                          color: AppColors.warning,
                          size: 26,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      body,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.xxxl),
                    AppButton(
                      label: 'Демо режимде көру',
                      icon: LucideIcons.eye,
                      variant: AppButtonVariant.secondary,
                      onPressed: onOpenDemoMode,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Демо режимде деректер қорына қосылмай, тек '
                      'дизайн-жүйені шолуға болады',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
