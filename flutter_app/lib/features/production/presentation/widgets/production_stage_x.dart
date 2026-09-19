import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../domain/entities/production_stage.dart';

/// Icon per stage `key` — a plain lookup, not a switch over a fixed
/// enum, since [ProductionStage] is database-driven (see that
/// entity's doc comment); an unrecognized/future key falls back to a
/// generic icon rather than throwing.
extension ProductionStageIcon on ProductionStage {
  IconData get icon {
    switch (key) {
      case 'waiting':
        return LucideIcons.clock;
      case 'cutting':
        return LucideIcons.scissors;
      case 'edge_banding':
        return LucideIcons.layers;
      case 'milling':
        return LucideIcons.cog;
      case 'painting':
        return LucideIcons.paintbrush;
      case 'assembly':
        return LucideIcons.hammer;
      case 'ready':
        return LucideIcons.checkCircle2;
      case 'ready_for_installation':
        return LucideIcons.truck;
      case 'installed':
        return LucideIcons.home;
      default:
        return LucideIcons.circle;
    }
  }
}
