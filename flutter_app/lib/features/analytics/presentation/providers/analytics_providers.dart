import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/supabase_provider.dart';
import '../../data/datasources/analytics_remote_datasource.dart';
import '../../data/repositories/analytics_repository_impl.dart';
import '../../domain/analytics_period.dart';
import '../../domain/entities/analytics_summary.dart';
import '../../domain/entities/employee_kpi.dart';
import '../../domain/entities/top_client.dart';
import '../../domain/repositories/analytics_repository.dart';
import '../../domain/usecases/get_analytics_summary_usecase.dart';
import '../../domain/usecases/get_employee_kpis_usecase.dart';
import '../../domain/usecases/get_top_clients_usecase.dart';

final analyticsRemoteDataSourceProvider = Provider<AnalyticsRemoteDataSource>((
  ref,
) {
  return AnalyticsRemoteDataSource(ref.watch(supabaseClientProvider));
});

final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {
  return AnalyticsRepositoryImpl(ref.watch(analyticsRemoteDataSourceProvider));
});

final getAnalyticsSummaryUseCaseProvider = Provider<GetAnalyticsSummaryUseCase>(
  (ref) => GetAnalyticsSummaryUseCase(ref.watch(analyticsRepositoryProvider)),
);

final getEmployeeKpisUseCaseProvider = Provider<GetEmployeeKpisUseCase>(
  (ref) => GetEmployeeKpisUseCase(ref.watch(analyticsRepositoryProvider)),
);

final getTopClientsUseCaseProvider = Provider<GetTopClientsUseCase>(
  (ref) => GetTopClientsUseCase(ref.watch(analyticsRepositoryProvider)),
);

/// Requirement: "Күн, апта, ай, жыл бойынша фильтр".
final analyticsPeriodTypeProvider = StateProvider<AnalyticsPeriodType>(
  (ref) => AnalyticsPeriodType.month,
);

/// Which occurrence of the selected period type is showing — e.g. with
/// [analyticsPeriodTypeProvider] set to month, this picks *which*
/// month. Changed via the ‹ › controls on the Analytics screen.
final analyticsReferenceDateProvider = StateProvider<DateTime>(
  (ref) => DateTime.now(),
);

final analyticsRangeProvider = Provider<DateRange>((ref) {
  final type = ref.watch(analyticsPeriodTypeProvider);
  final reference = ref.watch(analyticsReferenceDateProvider);
  return computePeriodRange(type, reference);
});

final analyticsPreviousRangeProvider = Provider<DateRange>((ref) {
  final type = ref.watch(analyticsPeriodTypeProvider);
  final reference = ref.watch(analyticsReferenceDateProvider);
  return computePreviousPeriodRange(type, reference);
});

final analyticsSummaryProvider = FutureProvider.autoDispose<AnalyticsSummary>((
  ref,
) {
  final range = ref.watch(analyticsRangeProvider);
  return ref
      .watch(getAnalyticsSummaryUseCaseProvider)
      .call(start: range.start, end: range.end)
      .then(
        (either) => either.match((failure) => throw failure, (data) => data),
      );
});

/// Requirement: "Салыстыру: алдыңғы кезеңмен" — the same-length period
/// immediately before [analyticsRangeProvider]'s range.
final analyticsPreviousSummaryProvider =
    FutureProvider.autoDispose<AnalyticsSummary>((ref) {
      final range = ref.watch(analyticsPreviousRangeProvider);
      return ref
          .watch(getAnalyticsSummaryUseCaseProvider)
          .call(start: range.start, end: range.end)
          .then(
            (either) =>
                either.match((failure) => throw failure, (data) => data),
          );
    });

final employeeKpisProvider = FutureProvider.autoDispose<List<EmployeeKpi>>((
  ref,
) {
  final range = ref.watch(analyticsRangeProvider);
  return ref
      .watch(getEmployeeKpisUseCaseProvider)
      .call(start: range.start, end: range.end)
      .then(
        (either) => either.match((failure) => throw failure, (data) => data),
      );
});

final topClientsProvider = FutureProvider.autoDispose<List<TopClient>>((ref) {
  final range = ref.watch(analyticsRangeProvider);
  return ref
      .watch(getTopClientsUseCaseProvider)
      .call(start: range.start, end: range.end)
      .then(
        (either) => either.match((failure) => throw failure, (data) => data),
      );
});
