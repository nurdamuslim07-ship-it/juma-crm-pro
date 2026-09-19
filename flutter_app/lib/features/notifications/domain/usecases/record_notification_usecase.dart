import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/app_notification.dart';
import '../repositories/notification_repository.dart';

class RecordNotificationUseCase {
  const RecordNotificationUseCase(this._repository);
  final NotificationRepository _repository;

  Future<Either<Failure, Unit>> call(AppNotification notification) {
    return _repository.record(notification);
  }
}
