import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/cart_item.dart';
import '../entities/inventory_batch.dart';
import '../entities/inventory_hold.dart';
import '../entities/material_category.dart';
import '../entities/material_stock.dart';
import '../entities/warehouse_location.dart';
import '../entities/warehouse_summary.dart';

abstract class WarehouseRepository {
  /// Direct read of `material_categories` — any active user (see
  /// `material_categories_read_all_active`).
  Future<Either<Failure, List<MaterialCategory>>> getCategories();

  /// Direct read of `warehouse_locations` — any active user.
  Future<Either<Failure, List<WarehouseLocation>>> getLocations();

  /// Requirement: "Қойма қалдығы" — routed through `get_materials()`.
  /// Empty for a caller with no `warehouse.read`.
  Future<Either<Failure, List<MaterialStock>>> getMaterials({
    String? categoryId,
    String? search,
    bool lowStockOnly = false,
  });

  /// Requirement: "Қойма аналитикасы" — routed through
  /// `get_warehouse_summary()`.
  Future<Either<Failure, WarehouseSummary>> getWarehouseSummary();

  /// Requirement: "Barcode" — null for no match or no `warehouse.read`,
  /// never an exception (a scan that doesn't resolve is benign).
  Future<Either<Failure, String?>> getMaterialIdByBarcode(String barcode);

  /// Requirement: "Партиялар" — direct read of `inventory_batches`
  /// (its own RLS already gates on `warehouse.read`), newest first.
  Future<Either<Failure, List<InventoryBatch>>> getBatches(String materialId);

  /// Direct read of active (unreleased) `inventory_holds` for one material.
  Future<Either<Failure, List<InventoryHold>>> getActiveHolds(
    String materialId,
  );

  /// Requirement: "Келіп түсу" — routed through `receive_materials()`.
  Future<Either<Failure, Unit>> receiveMaterials({
    required String materialId,
    required String locationId,
    required num quantity,
    required int costPerUnitTiyn,
    String? batchNumber,
    String? supplierPartnerId,
  });

  /// Requirement: "Шығыс" + "Себетке шығару" — routed through
  /// `issue_materials()`, one call for the whole cart.
  Future<Either<Failure, Unit>> issueMaterials({
    required List<CartItem> items,
    String? orderId,
  });

  /// Requirement: "Production резерві" — routed through
  /// `reserve_material_for_order()`. This is the write path that keeps
  /// `inventory_balances.reserved_quantity` in sync, which is what
  /// makes Production's `materials_sufficient` flag meaningful.
  Future<Either<Failure, String>> reserveMaterialForOrder({
    required String orderId,
    required String materialId,
    required num quantity,
    String? locationId,
  });

  Future<Either<Failure, Unit>> releaseOrderReservation(String reservationId);

  /// Requirement: "Резерв" — a generic, non-order hold.
  Future<Either<Failure, String>> createHold({
    required String materialId,
    required String locationId,
    required num quantity,
    String? reason,
  });

  Future<Either<Failure, Unit>> releaseHold(String holdId);
}
