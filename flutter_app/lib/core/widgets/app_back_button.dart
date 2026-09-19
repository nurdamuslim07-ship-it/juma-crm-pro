import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../router/route_paths.dart';

/// Preserve route-level back guards; section roots return to the dashboard.
class AppBackButton extends StatelessWidget {
  const AppBackButton({super.key});
  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: MaterialLocalizations.of(context).backButtonTooltip,
    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 21),
    onPressed: () async {
      final handled = await Navigator.of(context).maybePop();
      if (!handled && context.mounted) {
        final router = GoRouter.maybeOf(context);
        if (router != null) router.go(RoutePaths.dashboard);
      }
    },
  );
}
