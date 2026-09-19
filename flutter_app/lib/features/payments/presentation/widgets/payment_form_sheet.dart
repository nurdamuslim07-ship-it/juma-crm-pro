import '../../../../core/widgets/press_motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/i18n/locale_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/payment.dart';
import '../../domain/payment_rules.dart';
import '../../domain/value_objects/payment_method.dart';
import '../providers/payment_providers.dart';
import 'payment_method_x.dart';

/// Create/edit sheet (requirements #1/#13) — opened from an order's
/// detail screen, since a payment always belongs to one order
/// (requirement #1 "Тапсырысқа төлем қосу"). In edit mode the amount
/// field is read-only: the `payments_prevent_tamper` trigger rejects
/// any attempt to change it server-side (see
/// supabase/migrations/20260713000016_payments_module.sql), so the
/// form doesn't offer an edit control that would only fail later.
class PaymentFormSheet extends ConsumerStatefulWidget {
  const PaymentFormSheet({
    super.key,
    required this.orderId,
    required this.clientId,
    required this.orderTotalTiyn,
    required this.alreadyPaidTiyn,
    this.existing,
  });

  final String orderId;
  final String clientId;
  final int orderTotalTiyn;
  final int alreadyPaidTiyn;
  final Payment? existing;

  static Future<bool?> open(
    BuildContext context, {
    required String orderId,
    required String clientId,
    required int orderTotalTiyn,
    required int alreadyPaidTiyn,
    Payment? existing,
  }) {
    return showAppBottomSheet<bool>(
      context: context,
      child: PaymentFormSheet(
        orderId: orderId,
        clientId: clientId,
        orderTotalTiyn: orderTotalTiyn,
        alreadyPaidTiyn: alreadyPaidTiyn,
        existing: existing,
      ),
    );
  }

  @override
  ConsumerState<PaymentFormSheet> createState() => _PaymentFormSheetState();
}

class _PaymentFormSheetState extends ConsumerState<PaymentFormSheet> {
  late final _amount = TextEditingController(
    text: widget.existing != null
        ? (widget.existing!.amountTiyn / 100).toStringAsFixed(0)
        : '',
  );
  late final _comment = TextEditingController(text: widget.existing?.comment);

  PaymentMethod _method = PaymentMethod.cash;
  DateTime _paidAt = DateTime.now();
  String? _receiptPath;
  bool _saving = false;
  bool _uploadingReceipt = false;

  int get _maxPayableForThisPayment {
    // Editing doesn't change the amount, so the cap only matters for
    // new payments — see maxPayableTiyn's doc comment.
    if (widget.existing != null) return widget.existing!.amountTiyn;
    return maxPayableTiyn(
      orderTotalTiyn: widget.orderTotalTiyn,
      alreadyPaidTiyn: widget.alreadyPaidTiyn,
    );
  }

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _method = existing.method;
      _paidAt = existing.paidAt;
      _receiptPath = existing.receiptUrl;
    }
  }

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

  Future<void> _attachReceipt() async {
    final strings = ref.read(appStringsProvider);
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (file == null) return;

    setState(() => _uploadingReceipt = true);
    final bytes = await file.readAsBytes();
    final result = await ref
        .read(uploadReceiptUseCaseProvider)
        .call(bytes: bytes, fileName: file.name);

    if (!mounted) return;
    setState(() => _uploadingReceipt = false);

    result.match(
      (failure) => AppToast.show(failure.message, tone: ToastTone.error),
      (path) {
        setState(() => _receiptPath = path);
        AppToast.show(strings.paymentReceiptAttached, tone: ToastTone.success);
      },
    );
  }

  Future<void> _save() async {
    final strings = ref.read(appStringsProvider);
    final isNew = widget.existing == null;

    if (isNew) {
      final major = num.tryParse(_amount.text.trim());
      if (major == null || major <= 0) {
        AppToast.show(strings.authFieldRequired, tone: ToastTone.error);
        return;
      }
      final amountTiyn = (major * 100).round();

      if (wouldOverpay(
        orderTotalTiyn: widget.orderTotalTiyn,
        alreadyPaidTiyn: widget.alreadyPaidTiyn,
        newAmountTiyn: amountTiyn,
      )) {
        AppToast.show(
          strings.paymentAmountExceedsRemaining,
          tone: ToastTone.error,
        );
        return;
      }

      setState(() => _saving = true);
      final result = await ref
          .read(createPaymentUseCaseProvider)
          .call(
            orderId: widget.orderId,
            clientId: widget.clientId,
            amountTiyn: amountTiyn,
            method: _method,
            paidAt: _paidAt,
            comment: _comment.text.trim().isEmpty ? null : _comment.text.trim(),
            receiptUrl: _receiptPath,
          );

      if (!mounted) return;
      setState(() => _saving = false);

      result.match(
        (failure) => AppToast.show(failure.message, tone: ToastTone.error),
        (_) {
          AppToast.show(strings.paymentCreatedToast, tone: ToastTone.success);
          Navigator.of(context).pop(true);
        },
      );
    } else {
      setState(() => _saving = true);
      final updated = Payment(
        id: widget.existing!.id,
        orderId: widget.existing!.orderId,
        orderNumber: widget.existing!.orderNumber,
        clientId: widget.existing!.clientId,
        clientName: widget.existing!.clientName,
        amountTiyn: widget.existing!.amountTiyn,
        method: _method,
        paidAt: _paidAt,
        recordedByEmployeeId: widget.existing!.recordedByEmployeeId,
        recordedByEmployeeName: widget.existing!.recordedByEmployeeName,
        comment: _comment.text.trim().isEmpty ? null : _comment.text.trim(),
        receiptUrl: _receiptPath,
        createdAt: widget.existing!.createdAt,
      );

      final result = await ref.read(updatePaymentUseCaseProvider).call(updated);

      if (!mounted) return;
      setState(() => _saving = false);

      result.match(
        (failure) => AppToast.show(failure.message, tone: ToastTone.error),
        (_) {
          AppToast.show(strings.paymentUpdatedToast, tone: ToastTone.success);
          Navigator.of(context).pop(true);
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);
    final currentUser = ref.watch(currentUserProvider);
    final isNew = widget.existing == null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          isNew ? strings.paymentNewTitle : strings.paymentEditTitle,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.xl),
        if (isNew) ...[
          AppTextField(
            label: strings.paymentFormAmountLabel,
            controller: _amount,
            prefixIcon: LucideIcons.banknote,
            keyboardType: const TextInputType.numberWithOptions(decimal: false),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              '${strings.paymentMaxAmountHint}: ${AppFormatters.tenge(_maxPayableForThisPayment)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ] else
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Text(
              '${strings.paymentFormAmountLabel}: ${AppFormatters.tenge(widget.existing!.amountTiyn)}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          strings.paymentFormMethodLabel,
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
        const SizedBox(height: AppSpacing.lg),
        Text(
          strings.paymentFormDateLabel,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: AppSpacing.xs),
        MotionInkWell(
          onTap: _pickDate,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).dividerColor),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.calendarDays, size: 20),
                const SizedBox(width: AppSpacing.md),
                Text(AppFormatters.date(_paidAt)),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppTextField(
          label: strings.paymentFormCommentLabel,
          controller: _comment,
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          strings.paymentFormReceiptLabel,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: AppSpacing.xs),
        AppButton(
          label: _receiptPath != null
              ? strings.paymentReceiptAttached
              : strings.paymentAttachReceipt,
          icon: _receiptPath != null
              ? LucideIcons.checkCircle2
              : LucideIcons.paperclip,
          variant: AppButtonVariant.secondary,
          loading: _uploadingReceipt,
          onPressed: _uploadingReceipt ? null : _attachReceipt,
        ),
        if (currentUser != null) ...[
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              const Icon(
                LucideIcons.userCog,
                size: 16,
                color: AppColors.textSecondaryLight,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '${strings.paymentFormResponsibleEmployeeLabel}: '
                '${widget.existing?.recordedByEmployeeName ?? currentUser.fullName}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ],
        const SizedBox(height: AppSpacing.xxl),
        AppButton(
          label: strings.commonSave,
          loading: _saving,
          onPressed: _saving ? null : _save,
        ),
      ],
    );
  }
}
