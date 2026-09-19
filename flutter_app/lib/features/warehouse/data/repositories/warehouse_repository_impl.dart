import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/cart_item.dart';
import '../../domain/entities/inventory_batch.dart';
import '../../domain/entities/inventory_hold.dart';
import '../../domain/entities/material_category.dart';
import '../../domain/entities/material_stock.dart';
import '../../domain/entities/warehouse_location.dart';
import '../../domain/entities/warehouse_summary.dart';
import '../../domain/repositories/warehouse_repository.dart';
import '../datasources/warehouse_remote_datasource.dart';

class WarehouseRepositoryImpl implements WarehouseRepository {
  WarehouseRepositoryImpl(this._remote);
  final WarehouseRemoteDataSource _remote;

  @override
  Future<Either<Failure, List<MaterialCategory>>> getCategories() async {
    try {
      return right(await _remote.getCategories());
    } on PostgrestException catch (e) {
      return left(_mapPostgrestError(e));
    } catch (e) {
      return left(mapUnexpectedError(e));
    }
  }

  @override
  Future<Either<Failure, List<WarehouseLocation>>> getLocations() async {
    try {
      return right(await _remote.getLocations());
    } on PostgrestException catch (e) {
      return left(_mapPostgrestError(e));
    } catch (e) {
      return left(mapUnexpectedError(e));
    }
  }

  @override
  Future<Either<Failure, List<MaterialStock>>> getMaterials({
    String? categoryId,
    String? search,
    bool lowStockOnly = false,
  }) async {
    try {
      final items = await _remote.getMaterials(
        categoryId: categoryId,
        search: search,
        lowStockOnly: lowStockOnly,
      );
      return right(items);
    } on PostgrestException catch (e) {
      return left(_mapPostgrestError(e));
    } catch (e) {
      return left(mapUnexpectedError(e));
    }
  }

  @override
  Future<Either<Failure, WarehouseSummary>> getWarehouseSummary() async {
    try {
      return right(await _remote.getWarehouseSummary());
    } on PostgrestException catch (e) {
      return left(_mapPostgrestError(e));
    } catch (e) {
      return left(mapUnexpectedError(e));
    }
  }

  @override
  Future<Either<Failure, String?>> getMaterialIdByBarcode(
    String barcode,
  ) async {
    try {
      return right(await _remote.getMaterialIdByBarcode(barcode));
    } on PostgrestException catch (e) {
      return left(_mapPostgrestError(e));
    } catch (e) {
      return left(mapUnexpectedError(e));
    }
  }

  @override
  Future<Either<Failure, List<InventoryBatch>>> getBatches(
    String materialId,
  ) async {
    try {
      return right(await _remote.getBatches(materialId));
    } on PostgrestException catch (e) {
      return left(_mapPostgrestError(e));
    } catch (e) {
      return left(mapUnexpectedError(e));
    }
  }

  @override
  Future<Either<Failure, List<InventoryHold>>> getActiveHolds(
    String materialId,
  ) async {
    try {
      return right(await _remote.getActiveHolds(materialId));
    } on PostgrestException catch (e) {
      return left(_mapPostgrestError(e));
    } catch (e) {
      return left(mapUnexpectedError(e));
    }
  }

  @override
  Future<Either<Failure, Unit>> receiveMaterials({
    required String materialId,
    required String locationId,
    required num quantity,
    required int costPerUnitTiyn,
    String? batchNumber,
    String? supplierPartnerId,
  }) async {
    try {
      await _remote.receiveMaterials(
        materialId: materialId,
        locationId: locationId,
        quantity: quantity,
        costPerUnitTiyn: costPerUnitTiyn,
        batchNumber: batchNumber,
        supplierPartnerId: supplierPartnerId,
      );
      return right(unit);
    } on ServerException catch (e) {
      return left(
        ValidationFailure(e.message ?? 'Келіп түсуді жазу мүмкін емес'),
      );
    } on PostgrestException catch (e) {
      return left(_mapPostgrestError(e));
    } catch (e) {
      return left(mapUnexpectedError(e));
    }
  }

  @override
  Future<Either<Failure, Unit>> issueMaterials({
    required List<CartItem> items,
    String? orderId,
  }) async {
    try {
      await _remote.issueMaterials(items: items, orderId: orderId);
      return right(unit);
    } on ServerException catch (e) {
      return left(ValidationFailure(e.message ?? 'Шығысты жазу мүмкін емес'));
    } on PostgrestException catch (e) {
      return left(_mapPostgrestError(e));
    } catch (e) {
      return left(mapUnexpectedError(e));
    }
  }

  @override
  Future<Either<Failure, String>> reserveMaterialForOrder({
    required String orderId,
    required String materialId,
    required num quantity,
    String? locationId,
  }) async {
    try {
      final id = await _remote.reserveMaterialForOrder(
        orderId: orderId,
        materialId: materialId,
        quantity: quantity,
        locationId: locationId,
      );
      return right(id);
    } on ServerException catch (e) {
      return left(ValidationFailure(e.message ?? 'Резервтеу мүмкін емес'));
    } on PostgrestException catch (e) {
      return left(_mapPostgrestError(e));
    } catch (e) {
      return left(mapUnexpectedError(e));
    }
  }

  @override
  Future<Either<Failure, Unit>> releaseOrderReservation(
    String reservationId,
  ) async {
    try {
      await _remote.releaseOrderReservation(reservationId);
      return right(unit);
    } on ServerException catch (e) {
      return left(ValidationFailure(e.message ?? 'Резерв табылмады'));
    } on PostgrestException catch (e) {
      return left(_mapPostgrestError(e));
    } catch (e) {
      return left(mapUnexpectedError(e));
    }
  }

  @override
  Future<Either<Failure, String>> createHold({
    required String materialId,
    required String locationId,
    required num quantity,
    String? reason,
  }) async {
    try {
      final id = await _remote.createHold(
        materialId: materialId,
        locationId: locationId,
        quantity: quantity,
        reason: reason,
      );
      return right(id);
    } on ServerException catch (e) {
      return left(ValidationFailure(e.message ?? 'Резервтеу мүмкін емес'));
    } on PostgrestException catch (e) {
      return left(_mapPostgrestError(e));
    } catch (e) {
      return left(mapUnexpectedError(e));
    }
  }

  @override
  Future<Either<Failure, Unit>> releaseHold(String holdId) async {
    try {
      await _remote.releaseHold(holdId);
      return right(unit);
    } on ServerException catch (e) {
      return left(ValidationFailure(e.message ?? 'Резерв табылмады'));
    } on PostgrestException catch (e) {
      return left(_mapPostgrestError(e));
    } catch (e) {
      return left(mapUnexpectedError(e));
    }
  }

  Failure _mapPostgrestError(PostgrestException e) {
    if (e.code == '42501') return PermissionFailure(e.message);
    if (e.code == 'P0002' || e.code == 'PGRST116') {
      return NotFoundFailure(e.message);
    }
    return ServerFailure(e.message);
  }
}
