import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../connectivity/connectivity_provider.dart';
import '../i18n/locale_provider.dart';
import '../theme/app_colors.dart';

/// Stage 4 Part 7's "if offline, show a sync banner" — the cached-
/// data/read-only browsing side of that requirement is Part 4/5's
/// offline-first cache, deferred to a follow-up stage (see
/// supabase/README.md); this banner is the connectivity signal alone,
/// built on [connectivityProvider].
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final isOnline = ref.watch(connectivityProvider).valueOrNull ?? true;

    if (isOnline) return const SizedBox.shrink();

    return Material(
      color: AppColors.warning,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.wifiOff, size: 16, color: Colors.white),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  strings.offlineBannerMessage,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
