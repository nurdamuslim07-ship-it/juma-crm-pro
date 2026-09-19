import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/i18n/locale_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../domain/entities/payment.dart';
import '../providers/payment_providers.dart';
import 'payment_form_sheet.dart';

/// Edit / view receipt / delete actions for one payment — shared by
/// the global Payments tab and an order's payment history.
Future<bool> openPaymentActions(
  BuildContext context,
  WidgetRef ref,
  Payment payment, {
  required int orderTotalTiyn,
  required int alreadyPaidTiyn,
}) async {
  final strings = ref.read(appStringsProvider);
  var changed = false;

  await showAppBottomSheet<void>(
    context: context,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (payment.receiptUrl != null)
          ListTile(
            leading: const Icon(LucideIcons.receipt),
            title: Text(strings.paymentViewReceipt),
            onTap: () async {
              Navigator.of(context).pop();
              final result = await ref
                  .read(paymentRepositoryProvider)
                  .getReceiptSignedUrl(payment.receiptUrl!);
              result.match(
                (failure) =>
                    AppToast.show(failure.message, tone: ToastTone.error),
                (url) async {
                  final uri = Uri.parse(url);
                  final ok = await canLaunchUrl(uri) && await launchUrl(uri);
                  if (!ok && context.mounted) {
                    AppToast.show(
                      strings.commonCannotOpenLink,
                      tone: ToastTone.error,
                    );
                  }
                },
              );
            },
          ),
        ListTile(
          leading: const Icon(LucideIcons.pencil),
          title: Text(strings.commonEdit),
          onTap: () async {
            Navigator.of(context).pop();
            final result = await PaymentFormSheet.open(
              context,
              orderId: payment.orderId,
              clientId: payment.clientId,
              orderTotalTiyn: orderTotalTiyn,
              alreadyPaidTiyn: alreadyPaidTiyn,
              existing: payment,
            );
            if (result == true) changed = true;
          },
        ),
        ListTile(
          leading: const Icon(LucideIcons.trash2, color: AppColors.danger),
          title: Text(
            strings.commonDelete,
            style: const TextStyle(color: AppColors.danger),
          ),
          onTap: () async {
            Navigator.of(context).pop();
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(strings.paymentDeleteConfirmTitle),
                content: Text(strings.paymentDeleteConfirmBody),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(strings.commonCancel),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text(
                      strings.commonDelete,
                      style: const TextStyle(color: AppColors.danger),
                    ),
                  ),
                ],
              ),
            );
            if (confirmed != true || !context.mounted) return;

            final result = await ref
                .read(deletePaymentUseCaseProvider)
                .call(payment.id);
            result.match(
              (failure) =>
                  AppToast.show(failure.message, tone: ToastTone.error),
              (_) {
                AppToast.show(
                  strings.paymentDeletedToast,
                  tone: ToastTone.success,
                );
                changed = true;
              },
            );
          },
        ),
      ],
    ),
  );

  return changed;
}
