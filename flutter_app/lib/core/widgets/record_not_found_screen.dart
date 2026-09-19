import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../i18n/locale_provider.dart';
import 'state_views.dart';

/// Generic fallback for a detail route reached via GoRouter `extra`
/// with no fetch-by-id path (e.g. AuditLogDetailScreen) when `extra`
/// is missing or the wrong type — a direct/refreshed navigation
/// (mainly a web concern) rather than a normal in-app tap. Shows a
/// real screen with a way back, never a blank page or a crash.
class RecordNotFoundScreen extends ConsumerWidget {
  const RecordNotFoundScreen({super.key, required this.backTo});

  /// Route to return to — passed explicitly rather than always
  /// `context.pop()`, since a direct/refreshed navigation may have no
  /// page to pop back to.
  final String backTo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(strings.recordNotFoundTitle)),
      body: EmptyView(
        icon: LucideIcons.searchX,
        title: strings.recordNotFoundTitle,
        description: strings.recordNotFoundDescription,
        actionLabel: strings.recordNotFoundBackAction,
        action: () => context.go(backTo),
      ),
    );
  }
}
