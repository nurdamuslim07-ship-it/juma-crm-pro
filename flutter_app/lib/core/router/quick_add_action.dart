import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../i18n/locale_provider.dart';
import 'route_paths.dart';
import '../../features/clients/presentation/widgets/client_form_sheet.dart';
import '../../features/clients/presentation/providers/client_providers.dart';
import '../../features/measurements/measurement_form.dart';
import '../../features/orders/domain/entities/customer_order.dart';
import '../../features/orders/presentation/providers/order_providers.dart';
import '../../features/payments/presentation/widgets/payment_form_sheet.dart';
import '../../features/payments/presentation/providers/payment_providers.dart';

enum QuickAddAction { client, order, measurement, payment, expense, photo }

Future<void> openQuickAddAction(
  BuildContext context,
  QuickAddAction action,
) async {
  final container = ProviderScope.containerOf(context);
  final ru = Localizations.localeOf(context).languageCode == 'ru';
  switch (action) {
    case QuickAddAction.client:
      if (await ClientFormSheet.open(context) == true) {
        container.invalidate(clientsListProvider);
      }
      return;
    case QuickAddAction.order:
      context.push(RoutePaths.orderNew);
      return;
    case QuickAddAction.measurement:
      await Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => const MeasurementForm()));
      return;
    case QuickAddAction.expense:
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(ru ? 'Добавление расхода' : 'Шығын қосу'),
          content: Text(
            ru
                ? 'Форма расходов пока не реализована.'
                : 'Шығын енгізу формасы әзірге дайын емес.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    case QuickAddAction.payment:
    case QuickAddAction.photo:
      final order = await Navigator.of(context).push<CustomerOrder>(
        MaterialPageRoute(builder: (_) => const _OrderPicker()),
      );
      if (order == null || !context.mounted) return;
      if (action == QuickAddAction.photo) {
        context.push(RoutePaths.productionOrderDetail(order.id));
      } else {
        final saved = await PaymentFormSheet.open(
          context,
          orderId: order.id,
          clientId: order.clientId,
          orderTotalTiyn: order.totalAmountTiyn,
          alreadyPaidTiyn: order.paidTiyn,
        );
        if (saved == true) {
          container.invalidate(orderPaymentsProvider(order.id));
          container.invalidate(orderDetailProvider(order.id));
          container.invalidate(ordersListProvider);
        }
      }
  }
}

// Independent of the list page's status/search filters.
final _quickOrders = FutureProvider.autoDispose<List<CustomerOrder>>((
  ref,
) async {
  final result = await ref.watch(getOrdersUseCaseProvider).call();
  return result.match((failure) => throw failure, (orders) => orders);
});

class _OrderPicker extends ConsumerWidget {
  const _OrderPicker();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ru = Localizations.localeOf(context).languageCode == 'ru';
    final strings = ref.watch(appStringsProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(ru ? 'Выберите заказ' : 'Тапсырысты таңдаңыз'),
      ),
      body: ref
          .watch(_quickOrders)
          .when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => Center(
              child: TextButton(
                onPressed: () => ref.invalidate(_quickOrders),
                child: Text(strings.commonRetry),
              ),
            ),
            data: (orders) => orders.isEmpty
                ? Center(
                    child: Text(
                      ru
                          ? 'Сначала создайте заказ'
                          : 'Алдымен тапсырыс жасаңыз',
                    ),
                  )
                : ListView.builder(
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      final order = orders[index];
                      return ListTile(
                        title: Text(order.clientName),
                        subtitle: Text(
                          '${order.orderNumber} · ${order.productType}',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.pop(context, order),
                      );
                    },
                  ),
          ),
    );
  }
}
