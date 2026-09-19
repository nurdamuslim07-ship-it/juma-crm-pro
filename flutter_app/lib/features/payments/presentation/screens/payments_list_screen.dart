import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/widgets/press_motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/i18n/locale_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/debounced_search_controller.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/state_views.dart';
import '../../domain/value_objects/payment_method.dart';
import '../providers/payment_providers.dart';
import '../widgets/payment_actions_sheet.dart';
import '../widgets/payment_list_tile.dart';
import '../widgets/payment_method_x.dart';

/// The global "Төлемдер" tab — search + filter across every payment
/// (requirements #15/#16). Creating a payment always happens from an
/// order's detail screen (see PaymentHistorySection), not here — a
/// payment has no meaning without an order to attach it to.
class PaymentsListScreen extends ConsumerStatefulWidget {
  const PaymentsListScreen({super.key});

  @override
  ConsumerState<PaymentsListScreen> createState() => _PaymentsListScreenState();
}

class _PaymentsListScreenState extends ConsumerState<PaymentsListScreen> {
  late final _search = DebouncedSearchController(
    onSearch: (value) =>
        ref.read(paymentSearchQueryProvider.notifier).state = value,
  );

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _pickDateFrom() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: ref.read(paymentDateFromProvider) ?? DateTime.now(),
      firstDate: DateTime(DateTime.now().year - 2),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      ref.read(paymentDateFromProvider.notifier).state = picked;
    }
  }

  Future<void> _pickDateTo() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: ref.read(paymentDateToProvider) ?? DateTime.now(),
      firstDate: DateTime(DateTime.now().year - 2),
      lastDate: DateTime.now(),
    );
    if (picked != null) ref.read(paymentDateToProvider.notifier).state = picked;
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(paymentsRealtimeProvider);
    final strings = ref.watch(appStringsProvider);
    final paymentsAsync = ref.watch(paymentsListProvider);
    final methodFilter = ref.watch(paymentMethodFilterProvider);
    final dateFrom = ref.watch(paymentDateFromProvider);
    final dateTo = ref.watch(paymentDateToProvider);
    final hasDateFilter = dateFrom != null || dateTo != null;

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: Text(strings.navPayments),
      ),
      body: Padding(
        padding: context.pageInsets,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _search.textController,
              onChanged: _search.onChanged,
              decoration: InputDecoration(
                hintText: strings.paymentsSearchHint,
                prefixIcon: const Icon(LucideIcons.search, size: 20),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _Chip(
                    label: strings.paymentFilterAllMethods,
                    selected: methodFilter == null,
                    onTap: () =>
                        ref.read(paymentMethodFilterProvider.notifier).state =
                            null,
                  ),
                  for (final method in PaymentMethod.values)
                    _Chip(
                      label: method.label(strings),
                      icon: method.icon,
                      selected: methodFilter == method,
                      onTap: () =>
                          ref.read(paymentMethodFilterProvider.notifier).state =
                              method,
                    ),
                  const SizedBox(width: AppSpacing.sm),
                  _Chip(
                    label: dateFrom != null
                        ? AppFormatters.date(dateFrom)
                        : strings.paymentFilterDateFrom,
                    icon: LucideIcons.calendarDays,
                    selected: dateFrom != null,
                    onTap: _pickDateFrom,
                  ),
                  _Chip(
                    label: dateTo != null
                        ? AppFormatters.date(dateTo)
                        : strings.paymentFilterDateTo,
                    icon: LucideIcons.calendarClock,
                    selected: dateTo != null,
                    onTap: _pickDateTo,
                  ),
                  if (hasDateFilter)
                    _Chip(
                      label: strings.paymentFilterClear,
                      icon: LucideIcons.x,
                      selected: false,
                      onTap: () {
                        ref.read(paymentDateFromProvider.notifier).state = null;
                        ref.read(paymentDateToProvider.notifier).state = null;
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Expanded(
              child: paymentsAsync.when(
                loading: () => const LoadingView(),
                error: (error, _) => ErrorView(
                  message: strings.dashboardLoadError,
                  retryLabel: strings.commonRetry,
                  onRetry: () => ref.invalidate(paymentsListProvider),
                ),
                data: (payments) {
                  if (payments.isEmpty) {
                    return EmptyView(
                      icon: LucideIcons.receipt,
                      title: strings.paymentsEmptyTitle,
                      description: strings.paymentsEmptyDescription,
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () async => ref.invalidate(paymentsListProvider),
                    child: ListView.builder(
                      itemCount: payments.length,
                      itemBuilder: (context, index) {
                        final payment = payments[index];
                        return PaymentListTile(
                          payment: payment,
                          onTap: () async {
                            // Global list doesn't have the order's
                            // total/paid on hand — edit still works
                            // (amount stays locked either way); the
                            // caps just aren't shown in this entry
                            // point, matching that a payment is best
                            // managed from its own order.
                            final changed = await openPaymentActions(
                              context,
                              ref,
                              payment,
                              orderTotalTiyn: payment.amountTiyn,
                              alreadyPaidTiyn: 0,
                            );
                            if (changed) ref.invalidate(paymentsListProvider);
                          },
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: MotionInkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.skyDeep
                : AppColors.skyDeep.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 14,
                  color: selected ? Colors.white : AppColors.skyDeep,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : AppColors.skyDeep,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
