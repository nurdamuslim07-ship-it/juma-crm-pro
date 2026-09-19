import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/widgets/press_motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/i18n/locale_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../domain/entities/purchase_order_detail.dart';
import '../../domain/purchase_order_totals.dart';
import '../../domain/purchase_validation.dart';
import '../providers/purchase_order_draft_items_provider.dart';
import '../providers/purchases_providers.dart';
import '../widgets/add_purchase_order_item_sheet.dart';
import '../widgets/purchase_material_picker_sheet.dart';
import '../widgets/responsible_employee_picker_sheet.dart';
import '../widgets/supplier_picker_sheet.dart';

/// Requirement: "Purchase Order құру" + "Өңдеу" — one form for both,
/// distinguished by [existing] (mirrors OrderFormScreen/PartnerFormScreen's
/// convention: null = create, non-null = edit, passed via the route's
/// `state.extra`). Editing is draft-only, enforced server-side by
/// `update_purchase_order()`.
class PurchaseOrderFormScreen extends ConsumerStatefulWidget {
  const PurchaseOrderFormScreen({super.key, this.existing});

  final PurchaseOrderDetail? existing;

  @override
  ConsumerState<PurchaseOrderFormScreen> createState() =>
      _PurchaseOrderFormScreenState();
}

class _PurchaseOrderFormScreenState
    extends ConsumerState<PurchaseOrderFormScreen> {
  late final _orderNumber = TextEditingController(
    text: widget.existing?.orderNumber,
  );
  late final _deliveryCost = TextEditingController(
    text: widget.existing?.deliveryCostTiyn.toString() ?? '0',
  );
  late final _vat = TextEditingController(
    text: widget.existing?.vatTiyn.toString() ?? '0',
  );
  late final _discount = TextEditingController(
    text: widget.existing?.discountTiyn.toString() ?? '0',
  );
  late final _comment = TextEditingController(text: widget.existing?.comment);

  String? _supplierPartnerId;
  String? _supplierName;
  String? _responsibleEmployeeUserId;
  String? _responsibleEmployeeName;
  DateTime? _expectedDeliveryDate;
  bool _saving = false;
  String? _orderNumberError;
  String? _supplierError;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _supplierPartnerId = existing.supplierPartnerId;
      _supplierName = existing.supplierName;
      _responsibleEmployeeUserId = existing.responsibleEmployeeId;
      _responsibleEmployeeName = existing.responsibleEmployeeName;
      _expectedDeliveryDate = existing.expectedDeliveryDate;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(purchaseOrderDraftItemsProvider.notifier).seed(existing.items);
      });
    }
  }

  @override
  void dispose() {
    _orderNumber.dispose();
    _deliveryCost.dispose();
    _vat.dispose();
    _discount.dispose();
    _comment.dispose();
    super.dispose();
  }

  int _parseTiyn(String text) =>
      (num.tryParse(text.replaceAll(',', '.')) ?? 0).round();

  Future<void> _pickSupplier() async {
    final picked = await SupplierPickerSheet.open(
      context,
      currentPartnerId: _supplierPartnerId,
    );
    if (picked == null) return;
    setState(() {
      _supplierPartnerId = picked.id;
      _supplierName = picked.displayName;
      _supplierError = null;
    });
  }

  Future<void> _pickResponsibleEmployee() async {
    final picked = await ResponsibleEmployeePickerSheet.open(
      context,
      currentUserId: _responsibleEmployeeUserId,
    );
    if (picked == null) return;
    setState(() {
      _responsibleEmployeeUserId = picked.userId;
      _responsibleEmployeeName = picked.fullName;
    });
  }

  Future<void> _pickExpectedDeliveryDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expectedDeliveryDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(DateTime.now().year + 1),
    );
    if (picked != null) setState(() => _expectedDeliveryDate = picked);
  }

  Future<void> _addItem() async {
    final material = await PurchaseMaterialPickerSheet.open(context);
    if (material == null || !mounted) return;
    final item = await AddPurchaseOrderItemSheet.open(context, material);
    if (item != null) {
      ref.read(purchaseOrderDraftItemsProvider.notifier).add(item);
    }
  }

  Future<void> _submit() async {
    final strings = ref.read(appStringsProvider);
    setState(() {
      _orderNumberError = _orderNumber.text.trim().isEmpty
          ? strings.purchasesOrderNumberRequiredError
          : null;
      _supplierError = _supplierPartnerId == null
          ? strings.purchasesSupplierRequiredError
          : null;
    });
    if (_orderNumberError != null || _supplierError != null) return;

    final items = ref.read(purchaseOrderDraftItemsProvider);
    final deliveryCostTiyn = _parseTiyn(_deliveryCost.text);
    final vatTiyn = _parseTiyn(_vat.text);
    final discountTiyn = _parseTiyn(_discount.text);

    final validationError = validatePurchaseOrderInput(
      supplierPartnerId: _supplierPartnerId,
      items: items,
      deliveryCostTiyn: deliveryCostTiyn,
      vatTiyn: vatTiyn,
      discountTiyn: discountTiyn,
    );
    if (validationError != null) {
      AppToast.show(validationError, tone: ToastTone.error);
      return;
    }

    setState(() => _saving = true);
    final comment = _comment.text.trim().isEmpty ? null : _comment.text.trim();

    final existing = widget.existing;
    final result = existing == null
        ? await ref
              .read(createPurchaseOrderUseCaseProvider)
              .call(
                orderNumber: _orderNumber.text.trim(),
                supplierPartnerId: _supplierPartnerId!,
                items: items,
                responsibleEmployeeId: _responsibleEmployeeUserId,
                expectedDeliveryDate: _expectedDeliveryDate,
                deliveryCostTiyn: deliveryCostTiyn,
                vatTiyn: vatTiyn,
                discountTiyn: discountTiyn,
                comment: comment,
              )
        : await ref
              .read(updatePurchaseOrderUseCaseProvider)
              .call(
                id: existing.id,
                supplierPartnerId: _supplierPartnerId!,
                items: items,
                responsibleEmployeeId: _responsibleEmployeeUserId,
                expectedDeliveryDate: _expectedDeliveryDate,
                deliveryCostTiyn: deliveryCostTiyn,
                vatTiyn: vatTiyn,
                discountTiyn: discountTiyn,
                comment: comment,
              );

    if (!mounted) return;
    setState(() => _saving = false);
    result.match(
      (failure) => AppToast.show(failure.message, tone: ToastTone.error),
      (_) {
        AppToast.show(
          existing == null
              ? strings.purchasesCreatedToast
              : strings.purchasesUpdatedToast,
          tone: ToastTone.success,
        );
        ref.invalidate(purchaseOrdersListProvider);
        if (existing != null) {
          ref.invalidate(purchaseOrderDetailProvider(existing.id));
        }
        Navigator.of(context).pop();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);
    final textTheme = Theme.of(context).textTheme;
    final draftItems = ref.watch(purchaseOrderDraftItemsProvider);
    final itemTotals = [
      for (final item in draftItems)
        computeItemTotalTiyn(
          quantity: item.quantity,
          unitPriceTiyn: item.unitPriceTiyn,
        ),
    ];
    final subtotalTiyn = computeSubtotalTiyn(itemTotals);
    final totalTiyn = computeOrderTotalTiyn(
      subtotalTiyn: subtotalTiyn,
      deliveryCostTiyn: _parseTiyn(_deliveryCost.text),
      vatTiyn: _parseTiyn(_vat.text),
      discountTiyn: _parseTiyn(_discount.text),
    );

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: Text(
          widget.existing == null
              ? strings.purchasesCreateTitle
              : strings.purchasesEditTitle,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          AppTextField(
            label: strings.purchasesOrderNumberLabel,
            controller: _orderNumber,
            errorText: _orderNumberError,
            enabled: widget.existing == null,
          ),
          const SizedBox(height: AppSpacing.md),
          MotionInkWell(
            onTap: _pickSupplier,
            borderRadius: BorderRadius.circular(12),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: strings.purchasesSupplierLabel,
                errorText: _supplierError,
                suffixIcon: const Icon(LucideIcons.chevronDown, size: 18),
              ),
              child: Text(_supplierName ?? ''),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          MotionInkWell(
            onTap: _pickResponsibleEmployee,
            borderRadius: BorderRadius.circular(12),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: strings.purchasesResponsibleEmployeeLabel,
                suffixIcon: const Icon(LucideIcons.chevronDown, size: 18),
              ),
              child: Text(_responsibleEmployeeName ?? ''),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          MotionInkWell(
            onTap: _pickExpectedDeliveryDate,
            borderRadius: BorderRadius.circular(12),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: strings.purchasesExpectedDeliveryLabel,
                suffixIcon: const Icon(LucideIcons.calendar, size: 18),
              ),
              child: Text(
                _expectedDeliveryDate == null
                    ? ''
                    : '${_expectedDeliveryDate!.day.toString().padLeft(2, '0')}.${_expectedDeliveryDate!.month.toString().padLeft(2, '0')}.${_expectedDeliveryDate!.year}',
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      strings.purchasesItemsTitle,
                      style: textTheme.titleMedium,
                    ),
                    TextButton.icon(
                      onPressed: _addItem,
                      icon: const Icon(LucideIcons.plus, size: 16),
                      label: Text(strings.purchasesAddItemAction),
                    ),
                  ],
                ),
                if (draftItems.isEmpty)
                  Text(strings.purchasesNoItems, style: textTheme.bodyMedium)
                else
                  for (final item in draftItems)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.materialName ?? '',
                                  style: textTheme.bodyMedium,
                                ),
                                Text(
                                  '${item.quantity} ${item.unit} · ${item.locationName ?? ''}',
                                  style: textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${(computeItemTotalTiyn(quantity: item.quantity, unitPriceTiyn: item.unitPriceTiyn) / 100).toStringAsFixed(0)} ₸',
                            style: textTheme.bodyMedium,
                          ),
                          IconButton(
                            icon: const Icon(LucideIcons.trash2, size: 18),
                            color: AppColors.danger,
                            onPressed: () => ref
                                .read(purchaseOrderDraftItemsProvider.notifier)
                                .remove(item),
                          ),
                        ],
                      ),
                    ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            label: strings.purchasesDeliveryCostLabel,
            controller: _deliveryCost,
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: strings.purchasesVatLabel,
            controller: _vat,
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: strings.purchasesDiscountLabel,
            controller: _discount,
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: strings.purchasesCommentLabel,
            controller: _comment,
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(strings.purchasesTotalLabel, style: textTheme.titleMedium),
              Text(
                '${(totalTiyn / 100).toStringAsFixed(0)} ₸',
                style: textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: strings.commonSave,
            icon: LucideIcons.check,
            loading: _saving,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
