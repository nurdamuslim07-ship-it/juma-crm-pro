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

/// Requirement: "Резерв" — a generic, non-order hold (quality
/// inspection, damaged-goods set-aside), distinct from
/// "Production резерві" ([ReserveMaterialSheet]).
class HoldMaterialSheet extends ConsumerStatefulWidget {
  const HoldMaterialSheet({super.key, required this.material});

  final MaterialStock material;

  static Future<bool?> open(BuildContext context, MaterialStock material) {
    return showAppBottomSheet<bool>(
      context: context,
      child: HoldMaterialSheet(material: material),
    );
  }

  @override
  ConsumerState<HoldMaterialSheet> createState() => _HoldMaterialSheetState();
}

class _HoldMaterialSheetState extends ConsumerState<HoldMaterialSheet> {
  final _quantity = TextEditingController();
  final _reason = TextEditingController();
  WarehouseLocation? _location;
  bool _saving = false;
  String? _quantityError;
  String? _locationError;

  @override
  void dispose() {
    _quantity.dispose();
    _reason.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final strings = ref.read(appStringsProvider);
    final quantity = num.tryParse(_quantity.text.replaceAll(',', '.'));
    setState(() {
      _quantityError = (quantity == null || quantity <= 0)
          ? strings.warehouseQuantityRequiredError
          : null;
      _locationError = _location == null
          ? strings.warehouseQuantityRequiredError
          : null;
    });
    if (_quantityError != null || _locationError != null) return;

    setState(() => _saving = true);
    final result = await ref
        .read(createHoldUseCaseProvider)
        .call(
          materialId: widget.material.materialId,
          locationId: _location!.id,
          quantity: quantity!,
          reason: _reason.text.trim().isEmpty ? null : _reason.text.trim(),
        );
    if (!mounted) return;
    setState(() => _saving = false);
    result.match(
      (failure) => AppToast.show(failure.message, tone: ToastTone.error),
      (_) {
        AppToast.show(
          strings.warehouseHoldCreatedToast,
          tone: ToastTone.success,
        );
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
          strings.warehouseHoldTitle,
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
        AppTextField(label: strings.warehouseReasonLabel, controller: _reason),
        const SizedBox(height: AppSpacing.md),
        MotionInkWell(
          onTap: () async {
            final picked = await LocationPickerSheet.open(
              context,
              currentLocationId: _location?.id,
            );
            if (picked != null) setState(() => _location = picked);
          },
          borderRadius: BorderRadius.circular(12),
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: strings.warehouseLocationLabel,
              errorText: _locationError,
              suffixIcon: const Icon(LucideIcons.chevronDown, size: 18),
            ),
            child: Text(_location?.name ?? ''),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        AppButton(
          label: strings.warehouseHoldAction,
          icon: LucideIcons.shieldAlert,
          loading: _saving,
          onPressed: _submit,
        ),
      ],
    );
  }
}
