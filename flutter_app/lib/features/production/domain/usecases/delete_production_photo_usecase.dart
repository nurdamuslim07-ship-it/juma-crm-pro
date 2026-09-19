import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../repositories/production_repository.dart';

class DeleteProductionPhotoUseCase {
  const DeleteProductionPhotoUseCase(this._repository);
  final ProductionRepository _repository;

  Future<Either<Failure, Unit>> call(String photoId) {
    return _repository.deletePhoto(photoId);
  }
}
