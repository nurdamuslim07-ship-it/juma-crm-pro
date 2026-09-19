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
import '../../../payments/domain/value_objects/payment_method.dart';
import '../../../payments/presentation/widgets/payment_method_x.dart';
import '../../domain/purchase_validation.dart';
import '../providers/purchases_providers.dart';

/// Requirement: "Жеткізушіге төлем" — records a payment against a
/// supplier, optionally tied to a specific invoice ([supplierInvoiceId]
/// null = "Аванс", a general advance). Reuses the Payments module's
/// [PaymentMethod] enum + its label/icon extension directly instead of
/// re-declaring the same 5 methods.
///
/// [invoiceRemainingTiyn] — pass the tied invoice's
/// `amountTiyn - paidAmountTiyn` when [supplierInvoiceId] is set, so
/// [validatePaymentAmount] can reject an over-payment against THAT
/// invoice before the round trip. Omit both for a reason-less advance,
/// which has no upper bound by design.
class RecordSupplierPaymentSheet extends ConsumerStatefulWidget {
  const RecordSupplierPaymentSheet({
    super.key,
    required this.partnerId,
    this.supplierInvoiceId,
    this.invoiceRemainingTiyn,
  });

  final String partnerId;
  final String? supplierInvoiceId;
  final int? invoiceRemainingTiyn;

  static Future<bool?> open(
    BuildContext context, {
    required String partnerId,
    String? supplierInvoiceId,
    int? invoiceRemainingTiyn,
  }) {
    return showAppBottomSheet<bool>(
      context: context,
      child: RecordSupplierPaymentSheet(
        partnerId: partnerId,
        supplierInvoiceId: supplierInvoiceId,
        invoiceRemainingTiyn: invoiceRemainingTiyn,
      ),
    );
  }

  @override
  ConsumerState<RecordSupplierPaymentSheet> createState() =>
      _RecordSupplierPaymentSheetState();
}

class _RecordSupplierPaymentSheetState
    extends ConsumerState<RecordSupplierPaymentSheet> {
  final _amount = TextEditingController();
  final _comment = TextEditingController();
  PaymentMethod _method = PaymentMethod.cash;
  DateTime _paidAt = DateTime.now();
  bool _saving = false;
  String? _amountError;

  @override
  void dispose() {
    _amount.dispose();
    _comment.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _paidAt,
      firstDate: DateTime(DateTime.now().year - 1),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _paidAt = picked);
  }

  Future<void> _submit() async {
    final strings = ref.read(appStringsProvider);
    final amountTiyn = (num.tryParse(_amount.text.replaceAll(',', '.')) ?? 0)
        .round();
    final validationError = validatePaymentAmount(
      amountTiyn: amountTiyn,
      invoiceRemainingTiyn: widget.invoiceRemainingTiyn,
    );
    setState(() => _amountError = validationError);
    if (validationError != null) return;

    setState(() => _saving = true);
    final methodIds = await ref.read(getPaymentMethodIdsUseCaseProvider).call();
    final methodId = methodIds.match(
      (failure) => null,
      (ids) => ids[_method.dbKey],
    );
    if (methodId == null) {
      if (!mounted) return;
      setState(() => _saving = false);
      AppToast.show(strings.purchasesLoadError, tone: ToastTone.error);
      return;
    }

    final result = await ref
        .read(addSupplierPaymentUseCaseProvider)
        .call(
          partnerId: widget.partnerId,
          amountTiyn: amountTiyn,
          methodId: methodId,
          supplierInvoiceId: widget.supplierInvoiceId,
          paidAt: _paidAt,
          comment: _comment.text.trim().isEmpty ? null : _comment.text.trim(),
          invoiceRemainingTiyn: widget.invoiceRemainingTiyn,
        );
    if (!mounted) return;
    setState(() => _saving = false);
    result.match(
      (failure) => AppToast.show(failure.message, tone: ToastTone.error),
      (_) {
        AppToast.show(
          strings.purchasesPaymentRecordedToast,
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
          strings.purchasesRecordPaymentAction,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          widget.supplierInvoiceId == null
              ? strings.purchasesAdvancePaymentLabel
              : strings.purchasesInvoiceLabel,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.lg),
        AppTextField(
          label: strings.purchasesPaymentAmountLabel,
          controller: _amount,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          errorText: _amountError,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          strings.purchasesPaymentMethodLabel,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final method in PaymentMethod.values)
              ChoiceChip(
                label: Text(method.label(strings)),
                avatar: Icon(method.icon, size: 16),
                selected: _method == method,
                onSelected: (_) => setState(() => _method = method),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        MotionInkWell(
          onTap: _pickDate,
          borderRadius: BorderRadius.circular(12),
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: strings.purchasesPaymentDateLabel,
              suffixIcon: const Icon(LucideIcons.calendar, size: 18),
            ),
            child: Text(
              '${_paidAt.day.toString().padLeft(2, '0')}.${_paidAt.month.toString().padLeft(2, '0')}.${_paidAt.year}',
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          label: strings.purchasesPaymentCommentLabel,
          controller: _comment,
        ),
        const SizedBox(height: AppSpacing.xl),
        AppButton(
          label: strings.purchasesRecordPaymentAction,
          icon: LucideIcons.banknote,
          loading: _saving,
          onPressed: _submit,
        ),
      ],
    );
  }
}
