import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/supabase_provider.dart';
import '../../../../core/realtime/table_realtime_provider.dart';
import '../../../auth/domain/entities/auth_user.dart';
import '../../data/datasources/production_remote_datasource.dart';
import '../../data/repositories/production_repository_impl.dart';
import '../../domain/entities/production_detail.dart';
import '../../domain/entities/production_master.dart';
import '../../domain/entities/production_queue_item.dart';
import '../../domain/entities/production_stage.dart';
import '../../domain/repositories/production_repository.dart';
import '../../domain/usecases/add_production_photo_usecase.dart';
import '../../domain/usecases/delete_production_photo_usecase.dart';
import '../../domain/usecases/get_masters_usecase.dart';
import '../../domain/usecases/get_order_production_detail_usecase.dart';
import '../../domain/usecases/get_production_queue_usecase.dart';
import '../../domain/usecases/get_production_stages_usecase.dart';
import '../../domain/usecases/move_order_to_stage_usecase.dart';
import '../../domain/usecases/set_order_master_usecase.dart';
import '../../domain/usecases/start_time_log_usecase.dart';
import '../../domain/usecases/stop_time_log_usecase.dart';

final productionRemoteDataSourceProvider = Provider<ProductionRemoteDataSource>(
  (ref) => ProductionRemoteDataSource(ref.watch(supabaseClientProvider)),
);

final productionRepositoryProvider = Provider<ProductionRepository>(
  (ref) =>
      ProductionRepositoryImpl(ref.watch(productionRemoteDataSourceProvider)),
);

final getProductionStagesUseCaseProvider = Provider<GetProductionStagesUseCase>(
  (ref) => GetProductionStagesUseCase(ref.watch(productionRepositoryProvider)),
);

final getMastersUseCaseProvider = Provider<GetMastersUseCase>(
  (ref) => GetMastersUseCase(ref.watch(productionRepositoryProvider)),
);

final getProductionQueueUseCaseProvider = Provider<GetProductionQueueUseCase>(
  (ref) => GetProductionQueueUseCase(ref.watch(productionRepositoryProvider)),
);

final getOrderProductionDetailUseCaseProvider =
    Provider<GetOrderProductionDetailUseCase>(
      (ref) => GetOrderProductionDetailUseCase(
        ref.watch(productionRepositoryProvider),
      ),
    );

final moveOrderToStageUseCaseProvider = Provider<MoveOrderToStageUseCase>(
  (ref) => MoveOrderToStageUseCase(ref.watch(productionRepositoryProvider)),
);

final setOrderMasterUseCaseProvider = Provider<SetOrderMasterUseCase>(
  (ref) => SetOrderMasterUseCase(ref.watch(productionRepositoryProvider)),
);

final startTimeLogUseCaseProvider = Provider<StartTimeLogUseCase>(
  (ref) => StartTimeLogUseCase(ref.watch(productionRepositoryProvider)),
);

final stopTimeLogUseCaseProvider = Provider<StopTimeLogUseCase>(
  (ref) => StopTimeLogUseCase(ref.watch(productionRepositoryProvider)),
);

final addProductionPhotoUseCaseProvider = Provider<AddProductionPhotoUseCase>(
  (ref) => AddProductionPhotoUseCase(ref.watch(productionRepositoryProvider)),
);

final deleteProductionPhotoUseCaseProvider =
    Provider<DeleteProductionPhotoUseCase>(
      (ref) =>
          DeleteProductionPhotoUseCase(ref.watch(productionRepositoryProvider)),
    );

/// Rarely changes — a plain FutureProvider (not autoDispose) so the
/// Kanban board and every picker sheet share one cached fetch instead
/// of re-querying `production_stages` on every rebuild.
final productionStagesProvider = FutureProvider<List<ProductionStage>>((ref) {
  return ref
      .watch(getProductionStagesUseCaseProvider)
      .call()
      .then(
        (either) => either.match((failure) => throw failure, (data) => data),
      );
});

final productionMastersProvider =
    FutureProvider.autoDispose<List<ProductionMaster>>((ref) {
      return ref
          .watch(getMastersUseCaseProvider)
          .call()
          .then(
            (either) =>
                either.match((failure) => throw failure, (data) => data),
          );
    });

/// Requirement: "QR код арқылы ... " search / free-text filter.
final productionSearchQueryProvider = StateProvider<String>((ref) => '');

/// `null` = "барлық кезеңдер" (every stage) — the Kanban board ignores
/// this (it always shows all columns); the phone queue list uses it.
final productionStageFilterProvider = StateProvider<String?>((ref) => null);

final productionMasterFilterProvider = StateProvider<String?>((ref) => null);

final productionQueueProvider =
    FutureProvider.autoDispose<List<ProductionQueueItem>>((ref) {
      final search = ref.watch(productionSearchQueryProvider);
      final stageId = ref.watch(productionStageFilterProvider);
      final masterId = ref.watch(productionMasterFilterProvider);
      return ref
          .watch(getProductionQueueUseCaseProvider)
          .call(stageId: stageId, masterId: masterId, search: search)
          .then(
            (either) =>
                either.match((failure) => throw failure, (data) => data),
          );
    });

final productionOrderDetailProvider = FutureProvider.autoDispose
    .family<ProductionDetail, String>((ref, orderId) {
      return ref
          .watch(getOrderProductionDetailUseCaseProvider)
          .call(orderId)
          .then(
            (either) =>
                either.match((failure) => throw failure, (data) => data),
          );
    });

/// UI-convenience only, per SECURITY_PLAN.md finding #6 — the RPCs'
/// own permission checks (see
/// supabase/migrations/20260713000020_production_module.sql) are the
/// real authorization boundary; this only decides which controls this
/// session's role set makes worth showing.
extension ProductionAccess on AuthUser {
  bool get canMoveProductionCards =>
      isDirector || hasRole('workshop_manager') || hasRole('master');
  bool get canAssignMaster =>
      isDirector || hasRole('workshop_manager') || hasRole('manager');
}

/// Stage 4 Part 1 — the production queue is order-status/stage driven,
/// so it subscribes to `orders` (a separate channel from
/// `ordersRealtimeProvider`'s own — cheap, and keeps this feature
/// decoupled from the orders feature). See `tableRealtimeProvider`'s
/// own doc comment for the general pattern.
final productionRealtimeProvider = tableRealtimeProvider('orders', (ref) {
  ref.invalidate(productionQueueProvider);
});
