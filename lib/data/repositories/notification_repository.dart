import '../models/notification_model.dart';

abstract class NotificationRepository {
  Future<List<AppNotification>> fetchNotifications();
}

class NotificationRepositoryImpl implements NotificationRepository {
  @override
  Future<List<AppNotification>> fetchNotifications() async {
    return const [];
  }
}
