import '../../../../core/widgets/app_back_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/i18n/locale_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/production_qr.dart';

/// Requirement: "QR код арқылы тапсырысты ашу" — scans a QR printed
/// from [ProductionQrCodeView] and pops with the decoded order id;
/// the caller (see production_queue_screen.dart) navigates to that
/// order's production detail. Any other QR content (a stranger's
/// code, a garbage scan) is silently ignored rather than surfaced as
/// an error — the camera view just keeps scanning.
class QrScannerScreen extends ConsumerStatefulWidget {
  const QrScannerScreen({super.key});

  @override
  ConsumerState<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends ConsumerState<QrScannerScreen> {
  bool _handled = false;

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue;
      if (raw == null) continue;
      final orderId = decodeOrderIdFromQrPayload(raw);
      if (orderId != null) {
        _handled = true;
        Navigator.of(context).pop(orderId);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: Text(strings.productionScanQrTitle),
      ),
      body: MobileScanner(
        onDetect: _onDetect,
        errorBuilder: (context, error) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  LucideIcons.cameraOff,
                  size: 48,
                  color: AppColors.warning,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  strings.productionCameraUnavailable,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
