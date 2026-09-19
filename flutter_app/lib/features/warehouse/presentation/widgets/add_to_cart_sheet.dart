import '../../../../core/widgets/press_motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/i18n/locale_provider.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../domain/entities/cart_item.dart';
import '../../domain/entities/material_stock.dart';
import '../../domain/entities/warehouse_location.dart';
import 'location_picker_sheet.dart';

/// Requirement: "Себетке шығару" — the first step of the cart flow:
/// pick a location + quantity for one material, added to the pending
/// cart (see `issue_cart_provider.dart`) but not yet submitted.
class AddToCartSheet extends ConsumerStatefulWidget {
  const AddToCartSheet({super.key, required this.material});

  final MaterialStock material;

  static Future<CartItem?> open(BuildContext context, MaterialStock material) {
    return showAppBottomSheet<CartItem>(
      context: context,
      child: AddToCartSheet(material: material),
    );
  }

  @override
  ConsumerState<AddToCartSheet> createState() => _AddToCartSheetState();
}

class _AddToCartSheetState extends ConsumerState<AddToCartSheet> {
  final _quantity = TextEditingController();
  WarehouseLocation? _location;
  String? _quantityError;
  String? _locationError;

  @override
  void dispose() {
    _quantity.dispose();
    super.dispose();
  }

  void _submit() {
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

    Navigator.of(context).pop(
      CartItem(
        materialId: widget.material.materialId,
        materialName: widget.material.name,
        locationId: _location!.id,
        locationName: _location!.name,
        unit: widget.material.unit,
        quantity: quantity!,
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
          strings.warehouseAddToCartAction,
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
          label: strings.warehouseAddToCartAction,
          icon: LucideIcons.shoppingCart,
          onPressed: _submit,
        ),
      ],
    );
  }
}
