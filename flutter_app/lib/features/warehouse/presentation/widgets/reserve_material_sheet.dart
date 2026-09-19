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

/// Requirement: "Production резерві" — routed through
/// `reserve_material_for_order()`. Never blocks on insufficient stock
/// (see that RPC's doc comment) — Production's own materials_sufficient
/// flag is the visible warning, not a refusal here.
class ReserveMaterialSheet extends ConsumerStatefulWidget {
  const ReserveMaterialSheet({super.key, required this.material});

  final MaterialStock material;

  static Future<bool?> open(BuildContext context, MaterialStock material) {
    return showAppBottomSheet<bool>(
      context: context,
      child: ReserveMaterialSheet(material: material),
    );
  }

  @override
  ConsumerState<ReserveMaterialSheet> createState() =>
      _ReserveMaterialSheetState();
}

class _ReserveMaterialSheetState extends ConsumerState<ReserveMaterialSheet> {
  final _orderId = TextEditingController();
  final _quantity = TextEditingController();
  WarehouseLocation? _location;
  bool _saving = false;
  String? _quantityError;
  String? _orderIdError;

  @override
  void dispose() {
    _orderId.dispose();
    _quantity.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final strings = ref.read(appStringsProvider);
    final quantity = num.tryParse(_quantity.text.replaceAll(',', '.'));
    setState(() {
      _orderIdError = _orderId.text.trim().isEmpty
          ? strings.warehouseQuantityRequiredError
          : null;
      _quantityError = (quantity == null || quantity <= 0)
          ? strings.warehouseQuantityRequiredError
          : null;
    });
    if (_orderIdError != null || _quantityError != null) return;

    setState(() => _saving = true);
    final result = await ref
        .read(reserveMaterialForOrderUseCaseProvider)
        .call(
          orderId: _orderId.text.trim(),
          materialId: widget.material.materialId,
          quantity: quantity!,
          locationId: _location?.id,
        );
    if (!mounted) return;
    setState(() => _saving = false);
    result.match(
      (failure) => AppToast.show(failure.message, tone: ToastTone.error),
      (_) {
        AppToast.show(strings.warehouseReservedToast, tone: ToastTone.success);
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
          strings.warehouseReserveTitle,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          widget.material.name,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: AppSpacing.lg),
        AppTextField(
          label: strings.warehouseOrderIdLabel,
          controller: _orderId,
          errorText: _orderIdError,
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          label: '${strings.warehouseQuantityLabel} (${widget.material.unit})',
          controller: _quantity,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          errorText: _quantityError,
        ),
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
              suffixIcon: const Icon(LucideIcons.chevronDown, size: 18),
            ),
            child: Text(_location?.name ?? ''),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        AppButton(
          label: strings.warehouseReserveAction,
          icon: LucideIcons.lock,
          loading: _saving,
          onPressed: _submit,
        ),
      ],
    );
  }
}
