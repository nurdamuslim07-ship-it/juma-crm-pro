import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/i18n/locale_provider.dart';
import '../../../../core/theme/app_radius.dart';
import '../../domain/value_objects/order_status.dart';
import 'order_status_x.dart';

/// Never conveys status by color alone (per the master spec's
/// accessibility requirement) — always paired with the Kazakh label
/// text, not just a colored dot.
class OrderStatusBadge extends ConsumerWidget {
  const OrderStatusBadge({
    super.key,
    required this.status,
    this.compact = false,
  });

  final OrderStatus status;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        status.label(strings),
        style: TextStyle(
          color: status.color,
          fontWeight: FontWeight.w700,
          fontSize: compact ? 11 : 13,
        ),
      ),
    );
  }
}
