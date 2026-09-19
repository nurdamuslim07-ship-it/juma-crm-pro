import '../../../../core/widgets/app_back_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/i18n/locale_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/warehouse_qr.dart';
import '../providers/warehouse_providers.dart';

/// Requirement: "Barcode" + "QR код" share one scanner — a scanned
/// code is first tried as a material QR payload
/// (`juma-material:<uuid>`); if that fails, the raw text is resolved
/// server-side as a literal barcode via `get_material_id_by_barcode()`
/// (see warehouse_qr.dart's `classifyScannedCode`). Pops with the
/// resolved material id, or null if nothing matched.
class WarehouseScannerScreen extends ConsumerStatefulWidget {
  const WarehouseScannerScreen({super.key});

  @override
  ConsumerState<WarehouseScannerScreen> createState() =>
      _WarehouseScannerScreenState();
}

class _WarehouseScannerScreenState
    extends ConsumerState<WarehouseScannerScreen> {
  bool _handled = false;

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_handled) return;
    for (final detected in capture.barcodes) {
      final raw = detected.rawValue;
      if (raw == null) continue;
      _handled = true;

      switch (classifyScannedCode(raw)) {
        case ScanResolvedMaterialId(:final materialId):
          if (mounted) Navigator.of(context).pop(materialId);
        case ScanBarcodeCandidate(:final barcode):
          final either = await ref
              .read(getMaterialIdByBarcodeUseCaseProvider)
              .call(barcode);
          if (!mounted) return;
          final materialId = either.match((failure) => null, (id) => id);
          if (materialId == null) {
            _handled = false;
          } else {
            Navigator.of(context).pop(materialId);
          }
      }
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: Text(strings.warehouseScanTitle),
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
                  strings.warehouseCameraUnavailable,
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
