import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'state_views.dart';

/// Placeholder for modules not yet built in this pass of
/// IMPLEMENTATION_ROADMAP.md — swapped out for the real screen when
/// that module's commit lands, never left in place permanently.
class ComingSoonScreen extends StatelessWidget {
  const ComingSoonScreen({super.key, required this.moduleTitle});
  final String moduleTitle;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(moduleTitle)),
      body: const EmptyView(
        icon: LucideIcons.hammer,
        title: 'Бұл модуль әзірленуде',
        description: 'Жақын арада қолжетімді болады',
      ),
    );
  }
}
