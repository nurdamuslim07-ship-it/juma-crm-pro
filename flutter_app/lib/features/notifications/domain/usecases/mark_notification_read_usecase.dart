import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../repositories/notification_repository.dart';

class MarkNotificationReadUseCase {
  const MarkNotificationReadUseCase(this._repository);
  final NotificationRepository _repository;

  Future<Either<Failure, Unit>> call(String id) {
    return _repository.markAsRead(id);
  }
}
