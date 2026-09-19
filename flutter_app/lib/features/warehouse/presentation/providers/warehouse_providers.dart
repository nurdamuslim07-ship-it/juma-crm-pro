import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/supabase_provider.dart';
import '../../../../core/realtime/table_realtime_provider.dart';
import '../../../auth/domain/entities/auth_user.dart';
import '../../data/datasources/warehouse_remote_datasource.dart';
import '../../data/repositories/warehouse_repository_impl.dart';
import '../../domain/entities/inventory_batch.dart';
import '../../domain/entities/inventory_hold.dart';
import '../../domain/entities/material_category.dart';
import '../../domain/entities/material_stock.dart';
import '../../domain/entities/warehouse_location.dart';
import '../../domain/entities/warehouse_summary.dart';
import '../../domain/repositories/warehouse_repository.dart';
import '../../domain/usecases/create_hold_usecase.dart';
import '../../domain/usecases/get_active_holds_usecase.dart';
import '../../domain/usecases/get_batches_usecase.dart';
import '../../domain/usecases/get_categories_usecase.dart';
import '../../domain/usecases/get_locations_usecase.dart';
import '../../domain/usecases/get_material_id_by_barcode_usecase.dart';
import '../../domain/usecases/get_materials_usecase.dart';
import '../../domain/usecases/get_warehouse_summary_usecase.dart';
import '../../domain/usecases/issue_materials_usecase.dart';
import '../../domain/usecases/receive_materials_usecase.dart';
import '../../domain/usecases/release_hold_usecase.dart';
import '../../domain/usecases/release_order_reservation_usecase.dart';
import '../../domain/usecases/reserve_material_for_order_usecase.dart';

final warehouseRemoteDataSourceProvider = Provider<WarehouseRemoteDataSource>(
  (ref) => WarehouseRemoteDataSource(ref.watch(supabaseClientProvider)),
);

final warehouseRepositoryProvider = Provider<WarehouseRepository>(
  (ref) =>
      WarehouseRepositoryImpl(ref.watch(warehouseRemoteDataSourceProvider)),
);

final getCategoriesUseCaseProvider = Provider<GetCategoriesUseCase>(
  (ref) => GetCategoriesUseCase(ref.watch(warehouseRepositoryProvider)),
);

final getLocationsUseCaseProvider = Provider<GetLocationsUseCase>(
  (ref) => GetLocationsUseCase(ref.watch(warehouseRepositoryProvider)),
);

final getMaterialsUseCaseProvider = Provider<GetMaterialsUseCase>(
  (ref) => GetMaterialsUseCase(ref.watch(warehouseRepositoryProvider)),
);

final getWarehouseSummaryUseCaseProvider = Provider<GetWarehouseSummaryUseCase>(
  (ref) => GetWarehouseSummaryUseCase(ref.watch(warehouseRepositoryProvider)),
);

final getMaterialIdByBarcodeUseCaseProvider =
    Provider<GetMaterialIdByBarcodeUseCase>(
      (ref) =>
          GetMaterialIdByBarcodeUseCase(ref.watch(warehouseRepositoryProvider)),
    );

final getBatchesUseCaseProvider = Provider<GetBatchesUseCase>(
  (ref) => GetBatchesUseCase(ref.watch(warehouseRepositoryProvider)),
);

final getActiveHoldsUseCaseProvider = Provider<GetActiveHoldsUseCase>(
  (ref) => GetActiveHoldsUseCase(ref.watch(warehouseRepositoryProvider)),
);

final receiveMaterialsUseCaseProvider = Provider<ReceiveMaterialsUseCase>(
  (ref) => ReceiveMaterialsUseCase(ref.watch(warehouseRepositoryProvider)),
);

final issueMaterialsUseCaseProvider = Provider<IssueMaterialsUseCase>(
  (ref) => IssueMaterialsUseCase(ref.watch(warehouseRepositoryProvider)),
);

final reserveMaterialForOrderUseCaseProvider =
    Provider<ReserveMaterialForOrderUseCase>(
      (ref) => ReserveMaterialForOrderUseCase(
        ref.watch(warehouseRepositoryProvider),
      ),
    );

final releaseOrderReservationUseCaseProvider =
    Provider<ReleaseOrderReservationUseCase>(
      (ref) => ReleaseOrderReservationUseCase(
        ref.watch(warehouseRepositoryProvider),
      ),
    );

final createHoldUseCaseProvider = Provider<CreateHoldUseCase>(
  (ref) => CreateHoldUseCase(ref.watch(warehouseRepositoryProvider)),
);

final releaseHoldUseCaseProvider = Provider<ReleaseHoldUseCase>(
  (ref) => ReleaseHoldUseCase(ref.watch(warehouseRepositoryProvider)),
);

/// Rarely changes — shared cached fetch, same convention as
/// `productionStagesProvider`.
final materialCategoriesProvider = FutureProvider<List<MaterialCategory>>((
  ref,
) {
  return ref
      .watch(getCategoriesUseCaseProvider)
      .call()
      .then((either) => either.match((failure) => throw failure, (d) => d));
});

final warehouseLocationsProvider = FutureProvider<List<WarehouseLocation>>((
  ref,
) {
  return ref
      .watch(getLocationsUseCaseProvider)
      .call()
      .then((either) => either.match((failure) => throw failure, (d) => d));
});

final materialsSearchQueryProvider = StateProvider<String>((ref) => '');
final materialsCategoryFilterProvider = StateProvider<String?>((ref) => null);
final materialsLowStockOnlyProvider = StateProvider<bool>((ref) => false);

final materialsListProvider = FutureProvider.autoDispose<List<MaterialStock>>((
  ref,
) {
  final search = ref.watch(materialsSearchQueryProvider);
  final categoryId = ref.watch(materialsCategoryFilterProvider);
  final lowStockOnly = ref.watch(materialsLowStockOnlyProvider);
  return ref
      .watch(getMaterialsUseCaseProvider)
      .call(categoryId: categoryId, search: search, lowStockOnly: lowStockOnly)
      .then((either) => either.match((failure) => throw failure, (d) => d));
});

/// Backs a single material's detail screen — re-derived from the same
/// list RPC filtered by search, since `get_materials()` has no
/// single-id variant of its own (a full row shape isn't needed twice).
final materialByIdProvider = FutureProvider.autoDispose
    .family<MaterialStock?, String>((ref, materialId) async {
      final either = await ref.watch(getMaterialsUseCaseProvider).call();
      return either.match(
        (failure) => throw failure,
        (items) => items.where((m) => m.materialId == materialId).firstOrNull,
      );
    });

final materialBatchesProvider = FutureProvider.autoDispose
    .family<List<InventoryBatch>, String>((ref, materialId) {
      return ref
          .watch(getBatchesUseCaseProvider)
          .call(materialId)
          .then((either) => either.match((failure) => throw failure, (d) => d));
    });

final materialActiveHoldsProvider = FutureProvider.autoDispose
    .family<List<InventoryHold>, String>((ref, materialId) {
      return ref
          .watch(getActiveHoldsUseCaseProvider)
          .call(materialId)
          .then((either) => either.match((failure) => throw failure, (d) => d));
    });

final warehouseSummaryProvider = FutureProvider.autoDispose<WarehouseSummary>((
  ref,
) {
  return ref
      .watch(getWarehouseSummaryUseCaseProvider)
      .call()
      .then((either) => either.match((failure) => throw failure, (d) => d));
});

/// UI-convenience only, per SECURITY_PLAN.md finding #6 — the RPCs'
/// own permission checks (see
/// supabase/migrations/20260713000021_warehouse_module.sql) are the
/// real authorization boundary.
extension WarehouseAccess on AuthUser {
  bool get canManageWarehouse =>
      isDirector || hasRole('warehouse') || hasRole('purchaser');
}

/// Stage 4 Part 1 — two channels (new/renamed materials, and
/// quantity/reservation changes) both refresh the same list, since
/// either can change what `materialsListProvider` should show. See
/// `tableRealtimeProvider`'s own doc comment for the general pattern.
final materialsRealtimeProvider = tableRealtimeProvider('materials', (ref) {
  ref.invalidate(materialsListProvider);
});

final inventoryBalancesRealtimeProvider = tableRealtimeProvider(
  'inventory_balances',
  (ref) => ref.invalidate(materialsListProvider),
);
