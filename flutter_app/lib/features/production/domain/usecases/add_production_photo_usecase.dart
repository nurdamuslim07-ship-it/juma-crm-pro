import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/production_photo.dart';
import '../repositories/production_repository.dart';

class AddProductionPhotoUseCase {
  const AddProductionPhotoUseCase(this._repository);
  final ProductionRepository _repository;

  Future<Either<Failure, ProductionPhoto>> call({
    required String orderId,
    required List<int> bytes,
    required String fileName,
    required String companyId,
  }) {
    return _repository.addPhoto(
      orderId: orderId,
      bytes: bytes,
      fileName: fileName,
      companyId: companyId,
    );
  }
}
