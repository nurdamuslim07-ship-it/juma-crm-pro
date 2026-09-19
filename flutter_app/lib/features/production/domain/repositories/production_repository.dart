import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/production_detail.dart';
import '../entities/production_master.dart';
import '../entities/production_photo.dart';
import '../entities/production_queue_item.dart';
import '../entities/production_stage.dart';

abstract class ProductionRepository {
  /// Direct read of the `production_stages` table (RLS already allows
  /// any active user to select it — see
  /// supabase/migrations/20260713000012_rls_policies.sql), ordered by
  /// `sort_order` — the owner's 9-stage Kanban column order.
  Future<Either<Failure, List<ProductionStage>>> getStages();

  /// Backs the master-assignment picker — routed through
  /// `get_masters()`, not the Employees module's `get_employees()`
  /// (see that RPC's doc comment for why). Empty for anyone who
  /// couldn't call [setOrderMaster] anyway.
  Future<Either<Failure, List<ProductionMaster>>> getMasters();

  /// Routed through `get_production_queue()` — see that RPC's doc
  /// comment for the director/manager/workshop_manager (all orders)
  /// vs. master/assistant (assigned-only) visibility split.
  Future<Either<Failure, List<ProductionQueueItem>>> getQueue({
    String? stageId,
    String? masterId,
    String? search,
  });

  /// Routed through `get_order_production_detail()` — raises (surfaced
  /// as a Failure) if the caller has no production visibility into
  /// this specific order at all.
  Future<Either<Failure, ProductionDetail>> getOrderDetail(String orderId);

  /// Requirement: "Drag & Drop Kanban" / "Өндіріс кезеңін ауыстыру" —
  /// routed through `move_order_to_stage()`.
  Future<Either<Failure, Unit>> moveOrderToStage({
    required String orderId,
    required String stageId,
    String? comment,
  });

  /// Requirement: "Жауапты шебер тағайындау" — director/workshop_manager/
  /// manager only, routed through `set_order_master()`.
  Future<Either<Failure, Unit>> setOrderMaster({
    required String orderId,
    required String masterId,
  });

  /// Requirement: "Уақыт журналдары" — returns the new log's id (needed
  /// to call [stopTimeLog] later), routed through `start_time_log()`.
  Future<Either<Failure, String>> startTimeLog({
    required String orderId,
    String? stageId,
  });

  Future<Either<Failure, Unit>> stopTimeLog(String logId);

  /// Requirement: "Фото тіркеу" — uploads to the private
  /// `order-photos` Storage bucket, then records the metadata row
  /// (kind = 'production') directly in `order_photos` (its own RLS
  /// already permits this for `production.write` holders — see
  /// 20260713000020_production_module.sql — so no RPC wrapper needed).
  Future<Either<Failure, ProductionPhoto>> addPhoto({
    required String orderId,
    required List<int> bytes,
    required String fileName,
    required String companyId,
  });

  Future<Either<Failure, Unit>> deletePhoto(String photoId);

  Future<Either<Failure, String>> getPhotoSignedUrl(String storagePath);
}
