import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'app_button.dart';
import 'glass_card.dart';
import 'stat_card.dart';

/// A fully static preview of the Liquid Glass design system — no
/// Supabase, no Riverpod data providers, no network calls of any
/// kind. This exists so the interface can be inspected (per the
/// request to "allow viewing the interface" without real backend
/// credentials) without reintroducing the crash this screen was added
/// to fix: nothing here reads `Supabase.instance`.
class DemoPreviewScreen extends StatelessWidget {
  const DemoPreviewScreen({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLightMid,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Демо режим — JUMA UI'),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: onBack,
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(
                    LucideIcons.info,
                    color: AppColors.warning,
                    size: 18,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  const Expanded(
                    child: Text(
                      'Бұл дерекқорсыз статикалық шолу. Кіру, сақтау және '
                      'басқа әрекеттер бұл режимде істемейді.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            Text(
              'KPI карталары',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: AppSpacing.md,
              mainAxisSpacing: AppSpacing.md,
              childAspectRatio: 1.3,
              children: const [
                StatCard(
                  label: 'Белсенді тапсырыстар',
                  value: '12',
                  icon: LucideIcons.clipboardList,
                ),
                StatCard(
                  label: 'Түскен төлемдер',
                  value: '1 400 000 ₸',
                  icon: LucideIcons.wallet,
                  tone: StatTone.success,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),
            Text('Glass карта', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.md),
            const GlassCard(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.sm),
                child: Text(
                  'JUMA UI Furniture CRM — ашық көк мөлдір (Liquid Glass) '
                  'дизайн жүйесі.',
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            Text('Батырмалар', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.md),
            AppButton(label: 'Негізгі батырма', onPressed: () {}),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: 'Қосымша батырма',
              variant: AppButtonVariant.secondary,
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}
