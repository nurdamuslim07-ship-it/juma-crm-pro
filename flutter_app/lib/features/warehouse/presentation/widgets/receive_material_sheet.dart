import '../../../../core/widgets/press_motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/i18n/locale_provider.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../domain/entities/material_stock.dart';
import '../../domain/entities/warehouse_location.dart';
import '../providers/warehouse_providers.dart';
import 'location_picker_sheet.dart';

/// Requirement: "Келіп түсу" — routed through `receive_materials()`.
class ReceiveMaterialSheet extends ConsumerStatefulWidget {
  const ReceiveMaterialSheet({super.key, required this.material});

  final MaterialStock material;

  static Future<bool?> open(BuildContext context, MaterialStock material) {
    return showAppBottomSheet<bool>(
      context: context,
      child: ReceiveMaterialSheet(material: material),
    );
  }

  @override
  ConsumerState<ReceiveMaterialSheet> createState() =>
      _ReceiveMaterialSheetState();
}

class _ReceiveMaterialSheetState extends ConsumerState<ReceiveMaterialSheet> {
  final _quantity = TextEditingController();
  final _cost = TextEditingController();
  final _batchNumber = TextEditingController();
  WarehouseLocation? _location;
  bool _saving = false;
  String? _quantityError;

  @override
  void dispose() {
    _quantity.dispose();
    _cost.dispose();
    _batchNumber.dispose();
    super.dispose();
  }

  Future<void> _pickLocation() async {
    final picked = await LocationPickerSheet.open(
      context,
      currentLocationId: _location?.id,
    );
    if (picked != null) setState(() => _location = picked);
  }

  Future<void> _submit() async {
    final strings = ref.read(appStringsProvider);
    final quantity = num.tryParse(_quantity.text.replaceAll(',', '.'));
    if (quantity == null || quantity <= 0) {
      setState(() => _quantityError = strings.warehouseQuantityRequiredError);
      return;
    }
    if (_location == null) {
      final picked = await LocationPickerSheet.open(context);
      if (picked == null || !mounted) return;
      setState(() => _location = picked);
    }
    setState(() {
      _quantityError = null;
      _saving = true;
    });

    final costTiyn = (num.tryParse(_cost.text.replaceAll(',', '.')) ?? 0)
        .round();
    final result = await ref
        .read(receiveMaterialsUseCaseProvider)
        .call(
          materialId: widget.material.materialId,
          locationId: _location!.id,
          quantity: quantity,
          costPerUnitTiyn: costTiyn,
          batchNumber: _batchNumber.text.trim().isEmpty
              ? null
              : _batchNumber.text.trim(),
          supplierPartnerId: widget.material.preferredPartnerId,
        );
    if (!mounted) return;
    setState(() => _saving = false);
    result.match(
      (failure) => AppToast.show(failure.message, tone: ToastTone.error),
      (_) {
        AppToast.show(strings.warehouseReceivedToast, tone: ToastTone.success);
        Navigator.of(context).pop(true);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          strings.warehouseReceiveTitle,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          widget.material.name,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: AppSpacing.lg),
        AppTextField(
          label: '${strings.warehouseQuantityLabel} (${widget.material.unit})',
          controller: _quantity,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          errorText: _quantityError,
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          label: strings.warehouseCostPerUnitLabel,
          controller: _cost,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          label: strings.warehouseBatchNumberLabel,
          controller: _batchNumber,
        ),
        const SizedBox(height: AppSpacing.md),
        MotionInkWell(
          onTap: _pickLocation,
          borderRadius: BorderRadius.circular(12),
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: strings.warehouseLocationLabel,
              suffixIcon: const Icon(LucideIcons.chevronDown, size: 18),
            ),
            child: Text(_location?.name ?? ''),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        AppButton(
          label: strings.warehouseReceiveAction,
          icon: LucideIcons.packageOpen,
          loading: _saving,
          onPressed: _submit,
        ),
      ],
    );
  }
}
