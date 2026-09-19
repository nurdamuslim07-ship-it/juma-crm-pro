import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/i18n/locale_provider.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../orders/domain/value_objects/order_status.dart';
import '../../../orders/presentation/widgets/order_status_x.dart';

/// Requirement: "Статус бойынша тапсырыстар" + "Телефонда карточкалар,
/// планшет/web-те grid және chart" — a plain breakdown list on phone,
/// a bar chart on tablet/web.
class OrdersByStatusSection extends ConsumerWidget {
  const OrdersByStatusSection({super.key, required this.ordersByStatus});

  final Map<OrderStatus, int> ordersByStatus;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final total = ordersByStatus.values.fold(0, (a, b) => a + b);
    final maxCount = ordersByStatus.values.fold(0, (a, b) => a > b ? a : b);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings.analyticsOrdersByStatusTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          if (total == 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Text(
                strings.analyticsNoDataForPeriod,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            )
          else if (context.isMobile)
            _StatusList(ordersByStatus: ordersByStatus, total: total)
          else
            SizedBox(
              height: 180,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: (maxCount == 0 ? 1 : maxCount).toDouble() * 1.2,
                  titlesData: FlTitlesData(
                    show: true,
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= OrderStatus.values.length) {
                            return const SizedBox.shrink();
                          }
                          final status = OrderStatus.values[index];
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              status.label(strings),
                              style: const TextStyle(fontSize: 9),
                              textAlign: TextAlign.center,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: false),
                  barGroups: [
                    for (var i = 0; i < OrderStatus.values.length; i++)
                      BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: (ordersByStatus[OrderStatus.values[i]] ?? 0)
                                .toDouble(),
                            color: OrderStatus.values[i].color,
                            width: 22,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatusList extends ConsumerWidget {
  const _StatusList({required this.ordersByStatus, required this.total});

  final Map<OrderStatus, int> ordersByStatus;
  final int total;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    return Column(
      children: [
        for (final status in OrderStatus.values)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: status.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    status.label(strings),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                Text(
                  '${ordersByStatus[status] ?? 0}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
