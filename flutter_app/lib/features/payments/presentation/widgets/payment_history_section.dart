import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/i18n/locale_provider.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/state_views.dart';
import '../providers/payment_providers.dart';
import 'payment_actions_sheet.dart';
import 'payment_form_sheet.dart';
import 'payment_list_tile.dart';

/// Requirement #2 "Төлем тарихы" — embedded in OrderDetailScreen
/// rather than only reachable from the global Payments tab, since a
/// payment always belongs to one order (requirement #1). Adding a
/// payment here is what actually changes the order's paid/remaining/
/// percent — see OrderPaymentProgress, which reads the same
/// active_payments-backed total this list does.
class PaymentHistorySection extends ConsumerWidget {
  const PaymentHistorySection({
    super.key,
    required this.orderId,
    required this.clientId,
    required this.orderTotalTiyn,
    required this.alreadyPaidTiyn,
    required this.onChanged,
  });

  final String orderId;
  final String clientId;
  final int orderTotalTiyn;
  final int alreadyPaidTiyn;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final paymentsAsync = ref.watch(orderPaymentsProvider(orderId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              strings.paymentHistoryTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            AppButton(
              label: strings.quickAddNewPayment,
              icon: LucideIcons.plus,
              expand: false,
              onPressed: alreadyPaidTiyn >= orderTotalTiyn
                  ? null
                  : () async {
                      final created = await PaymentFormSheet.open(
                        context,
                        orderId: orderId,
                        clientId: clientId,
                        orderTotalTiyn: orderTotalTiyn,
                        alreadyPaidTiyn: alreadyPaidTiyn,
                      );
                      if (created == true) {
                        ref.invalidate(orderPaymentsProvider(orderId));
                        onChanged();
                      }
                    },
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        paymentsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
            child: LoadingView(),
          ),
          error: (error, _) => Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
            child: ErrorView(message: strings.dashboardLoadError),
          ),
          data: (payments) {
            if (payments.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                child: EmptyView(
                  icon: LucideIcons.receipt,
                  title: strings.paymentsEmptyTitle,
                ),
              );
            }
            return Column(
              children: [
                for (final payment in payments)
                  PaymentListTile(
                    payment: payment,
                    showOrderInfo: false,
                    onTap: () async {
                      final changed = await openPaymentActions(
                        context,
                        ref,
                        payment,
                        orderTotalTiyn: orderTotalTiyn,
                        alreadyPaidTiyn: alreadyPaidTiyn,
                      );
                      if (changed) {
                        ref.invalidate(orderPaymentsProvider(orderId));
                        onChanged();
                      }
                    },
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
