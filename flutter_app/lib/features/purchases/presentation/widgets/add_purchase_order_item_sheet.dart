import '../../../../core/widgets/press_motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/i18n/locale_provider.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../warehouse/domain/entities/material_stock.dart';
import '../../../warehouse/domain/entities/warehouse_location.dart';
import '../../../warehouse/presentation/widgets/location_picker_sheet.dart';
import '../../domain/entities/purchase_order_item.dart';
import '../../domain/purchase_validation.dart';

/// Requirement: "Purchase Items" line — the second step of "Material
/// Picker" (see [PurchaseMaterialPickerSheet]): once a material is
/// picked, this asks for quantity/unit price/warehouse location and
/// returns the resulting [PurchaseOrderItem] to the caller, which adds
/// it to [purchaseOrderDraftItemsProvider]. Reuses the Warehouse
/// module's own [LocationPickerSheet] directly — same
/// `warehouse_locations` list, no reason to duplicate it.
class AddPurchaseOrderItemSheet extends ConsumerStatefulWidget {
  const AddPurchaseOrderItemSheet({super.key, required this.material});

  final MaterialStock material;

  static Future<PurchaseOrderItem?> open(
    BuildContext context,
    MaterialStock material,
  ) {
    return showAppBottomSheet<PurchaseOrderItem>(
      context: context,
      child: AddPurchaseOrderItemSheet(material: material),
    );
  }

  @override
  ConsumerState<AddPurchaseOrderItemSheet> createState() =>
      _AddPurchaseOrderItemSheetState();
}

class _AddPurchaseOrderItemSheetState
    extends ConsumerState<AddPurchaseOrderItemSheet> {
  final _quantity = TextEditingController();
  late final _unitPrice = TextEditingController(
    text: widget.material.costPerUnitTiyn > 0
        ? widget.material.costPerUnitTiyn.toString()
        : '',
  );
  WarehouseLocation? _location;
  String? _quantityError;
  String? _unitPriceError;
  String? _locationError;

  @override
  void dispose() {
    _quantity.dispose();
    _unitPrice.dispose();
    super.dispose();
  }

  void _submit() {
    final strings = ref.read(appStringsProvider);
    final quantity = num.tryParse(_quantity.text.replaceAll(',', '.')) ?? 0;
    final unitPriceTiyn =
        (num.tryParse(_unitPrice.text.replaceAll(',', '.')) ?? 0).round();
    setState(() {
      _quantityError = validateItemQuantity(quantity);
      _unitPriceError = validateItemUnitPriceTiyn(unitPriceTiyn);
      _locationError = _location == null
          ? strings.purchasesLocationRequiredError
          : null;
    });
    if (_quantityError != null ||
        _unitPriceError != null ||
        _locationError != null) {
      return;
    }

    Navigator.of(context).pop(
      PurchaseOrderItem(
        materialId: widget.material.materialId,
        materialName: widget.material.name,
        quantity: quantity,
        unit: widget.material.unit,
        unitPriceTiyn: unitPriceTiyn,
        locationId: _location!.id,
        locationName: _location!.name,
      ),
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
          strings.purchasesAddItemAction,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          widget.material.name,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: AppSpacing.lg),
        AppTextField(
          label: '${strings.purchasesQuantityLabel} (${widget.material.unit})',
          controller: _quantity,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          errorText: _quantityError,
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          label: strings.purchasesUnitPriceLabel,
          controller: _unitPrice,
          keyboardType: TextInputType.number,
          errorText: _unitPriceError,
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
              labelText: strings.purchasesLocationLabel,
              errorText: _locationError,
              suffixIcon: const Icon(LucideIcons.chevronDown, size: 18),
            ),
            child: Text(_location?.name ?? ''),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        AppButton(
          label: strings.purchasesAddItemAction,
          icon: LucideIcons.plus,
          onPressed: _submit,
        ),
      ],
    );
  }
}
