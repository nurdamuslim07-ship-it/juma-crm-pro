import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show PostgrestException, StorageException;

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/production_detail.dart';
import '../../domain/entities/production_master.dart';
import '../../domain/entities/production_photo.dart';
import '../../domain/entities/production_queue_item.dart';
import '../../domain/entities/production_stage.dart';
import '../../domain/repositories/production_repository.dart';
import '../datasources/production_remote_datasource.dart';

class ProductionRepositoryImpl implements ProductionRepository {
  ProductionRepositoryImpl(this._remote);
  final ProductionRemoteDataSource _remote;

  @override
  Future<Either<Failure, List<ProductionStage>>> getStages() async {
    try {
      return right(await _remote.getStages());
    } on PostgrestException catch (e) {
      return left(_mapPostgrestError(e));
    } catch (e) {
      return left(mapUnexpectedError(e));
    }
  }

  @override
  Future<Either<Failure, List<ProductionMaster>>> getMasters() async {
    try {
      return right(await _remote.getMasters());
    } on PostgrestException catch (e) {
      return left(_mapPostgrestError(e));
    } catch (e) {
      return left(mapUnexpectedError(e));
    }
  }

  @override
  Future<Either<Failure, List<ProductionQueueItem>>> getQueue({
    String? stageId,
    String? masterId,
    String? search,
  }) async {
    try {
      final items = await _remote.getQueue(
        stageId: stageId,
        masterId: masterId,
        search: search,
      );
      return right(items);
    } on PostgrestException catch (e) {
      return left(_mapPostgrestError(e));
    } catch (e) {
      return left(mapUnexpectedError(e));
    }
  }

  @override
  Future<Either<Failure, ProductionDetail>> getOrderDetail(
    String orderId,
  ) async {
    try {
      return right(await _remote.getOrderDetail(orderId));
    } on NotFoundException catch (e) {
      return left(NotFoundFailure(e.message ?? 'Тапсырыс табылмады'));
    } on PostgrestException catch (e) {
      return left(_mapPostgrestError(e));
    } catch (e) {
      return left(mapUnexpectedError(e));
    }
  }

  @override
  Future<Either<Failure, Unit>> moveOrderToStage({
    required String orderId,
    required String stageId,
    String? comment,
  }) async {
    try {
      await _remote.moveOrderToStage(
        orderId: orderId,
        stageId: stageId,
        comment: comment,
      );
      return right(unit);
    } on ServerException catch (e) {
      return left(
        e.message == null
            ? const PermissionFailure()
            : PermissionFailure(e.message!),
      );
    } on PostgrestException catch (e) {
      return left(_mapPostgrestError(e));
    } catch (e) {
      return left(mapUnexpectedError(e));
    }
  }

  @override
  Future<Either<Failure, Unit>> setOrderMaster({
    required String orderId,
    required String masterId,
  }) async {
    try {
      await _remote.setOrderMaster(orderId: orderId, masterId: masterId);
      return right(unit);
    } on ServerException catch (e) {
      return left(
        e.message == null
            ? const PermissionFailure()
            : PermissionFailure(e.message!),
      );
    } on PostgrestException catch (e) {
      return left(_mapPostgrestError(e));
    } catch (e) {
      return left(mapUnexpectedError(e));
    }
  }

  @override
  Future<Either<Failure, String>> startTimeLog({
    required String orderId,
    String? stageId,
  }) async {
    try {
      final id = await _remote.startTimeLog(orderId: orderId, stageId: stageId);
      return right(id);
    } on ServerException catch (e) {
      return left(
        ValidationFailure(e.message ?? 'Уақыт журналын бастау мүмкін емес'),
      );
    } on PostgrestException catch (e) {
      return left(_mapPostgrestError(e));
    } catch (e) {
      return left(mapUnexpectedError(e));
    }
  }

  @override
  Future<Either<Failure, Unit>> stopTimeLog(String logId) async {
    try {
      await _remote.stopTimeLog(logId);
      return right(unit);
    } on ServerException catch (e) {
      return left(ValidationFailure(e.message ?? 'Уақыт журналы табылмады'));
    } on PostgrestException catch (e) {
      return left(_mapPostgrestError(e));
    } catch (e) {
      return left(mapUnexpectedError(e));
    }
  }

  @override
  Future<Either<Failure, ProductionPhoto>> addPhoto({
    required String orderId,
    required List<int> bytes,
    required String fileName,
    required String companyId,
  }) async {
    try {
      final photo = await _remote.addPhoto(
        orderId: orderId,
        bytes: bytes,
        fileName: fileName,
        companyId: companyId,
      );
      return right(photo);
    } on StorageException catch (e) {
      return left(ServerFailure(e.message));
    } on PostgrestException catch (e) {
      return left(_mapPostgrestError(e));
    } catch (e) {
      return left(mapUnexpectedError(e));
    }
  }

  @override
  Future<Either<Failure, Unit>> deletePhoto(String photoId) async {
    try {
      await _remote.deletePhoto(photoId);
      return right(unit);
    } on PostgrestException catch (e) {
      return left(_mapPostgrestError(e));
    } catch (e) {
      return left(mapUnexpectedError(e));
    }
  }

  @override
  Future<Either<Failure, String>> getPhotoSignedUrl(String storagePath) async {
    try {
      return right(await _remote.getPhotoSignedUrl(storagePath));
    } on StorageException catch (e) {
      return left(ServerFailure(e.message));
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
