import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/i18n/locale_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// Scans a QR encoding an invite code (see InviteEmployeeScreen, which
/// generates it via `qr_flutter`) and pops with the raw decoded
/// string — unlike production's order QR, an invite code has no
/// custom payload envelope, it's just the code itself. Modeled on
/// `features/production/presentation/screens/qr_scanner_screen.dart`.
class InviteCodeScannerScreen extends ConsumerStatefulWidget {
  const InviteCodeScannerScreen({super.key});

  @override
  ConsumerState<InviteCodeScannerScreen> createState() =>
      _InviteCodeScannerScreenState();
}

class _InviteCodeScannerScreenState
    extends ConsumerState<InviteCodeScannerScreen> {
  bool _handled = false;

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue?.trim();
      if (raw == null || raw.isEmpty) continue;
      _handled = true;
      Navigator.of(context).pop(raw);
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(strings.joinCompanyScanQrAction)),
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
