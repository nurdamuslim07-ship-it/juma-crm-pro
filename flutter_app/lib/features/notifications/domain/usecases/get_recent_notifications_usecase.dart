import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/app_notification.dart';
import '../repositories/notification_repository.dart';

class GetRecentNotificationsUseCase {
  const GetRecentNotificationsUseCase(this._repository);
  final NotificationRepository _repository;

  Future<Either<Failure, List<AppNotification>>> call({int limit = 50}) {
    return _repository.getRecent(limit: limit);
  }
}
