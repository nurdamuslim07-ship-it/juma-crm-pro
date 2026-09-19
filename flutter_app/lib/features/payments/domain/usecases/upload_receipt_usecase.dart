import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../repositories/payment_repository.dart';

class UploadReceiptUseCase {
  const UploadReceiptUseCase(this._repository);
  final PaymentRepository _repository;

  Future<Either<Failure, String>> call({
    required List<int> bytes,
    required String fileName,
  }) {
    return _repository.uploadReceipt(bytes: bytes, fileName: fileName);
  }
}
