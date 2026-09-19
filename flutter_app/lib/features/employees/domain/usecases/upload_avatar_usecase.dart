import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../repositories/employee_repository.dart';

class UploadAvatarUseCase {
  const UploadAvatarUseCase(this._repository);
  final EmployeeRepository _repository;

  Future<Either<Failure, String>> call({
    required String userId,
    required List<int> bytes,
    required String fileName,
  }) {
    return _repository.uploadAvatar(
      userId: userId,
      bytes: bytes,
      fileName: fileName,
    );
  }
}
