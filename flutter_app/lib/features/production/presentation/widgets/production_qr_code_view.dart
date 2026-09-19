import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/i18n/locale_provider.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../domain/production_qr.dart';

/// Requirement: "QR код арқылы тапсырысты ашу" — the QR shown/printed
/// on an order's production detail screen; scanning it (see
/// qr_scanner_screen.dart) decodes the same [encodeOrderQrPayload]
/// format and navigates straight back to this screen.
class ProductionQrCodeView extends ConsumerWidget {
  const ProductionQrCodeView({
    super.key,
    required this.orderId,
    required this.orderNumber,
  });

  final String orderId;
  final String orderNumber;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);

    return GlassCard(
      child: Column(
        children: [
          Text(
            strings.productionQrTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: QrImageView(
              data: encodeOrderQrPayload(orderId),
              size: 160,
              gapless: true,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(orderNumber, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
