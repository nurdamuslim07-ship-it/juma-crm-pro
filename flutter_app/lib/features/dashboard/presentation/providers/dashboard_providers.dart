import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/supabase_provider.dart';
import '../../data/datasources/dashboard_remote_datasource.dart';
import '../../data/repositories/dashboard_repository_impl.dart';
import '../../domain/entities/dashboard_summary.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../../domain/usecases/get_dashboard_summary_usecase.dart';

final dashboardRemoteDataSourceProvider = Provider<DashboardRemoteDataSource>((
  ref,
) {
  return DashboardRemoteDataSource(ref.watch(supabaseClientProvider));
});

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepositoryImpl(ref.watch(dashboardRemoteDataSourceProvider));
});

final getDashboardSummaryUseCaseProvider = Provider<GetDashboardSummaryUseCase>(
  (ref) {
    return GetDashboardSummaryUseCase(ref.watch(dashboardRepositoryProvider));
  },
);

/// autoDispose + FutureProvider so pull-to-refresh (`ref.invalidate`)
/// re-runs the RPC without keeping a stale AsyncNotifier around
/// between dashboard visits.
final dashboardSummaryProvider = FutureProvider.autoDispose<DashboardSummary>((
  ref,
) {
  return ref
      .watch(getDashboardSummaryUseCaseProvider)
      .call()
      .then(
        (either) => either.match((failure) => throw failure, (data) => data),
      );
});
