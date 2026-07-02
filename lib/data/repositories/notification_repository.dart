import '../api/caregiver_api.dart';
import '../mappers/api_mappers.dart';
import '../models/notification_model.dart';

abstract class NotificationRepository {
  Future<List<AppNotification>> fetchNotifications();
  Future<int> getUnreadCount();
  Future<void> markRead(String id);
  Future<void> markAllRead();
  Future<void> deleteNotification(String id);
}

class NotificationRepositoryImpl implements NotificationRepository {
  NotificationRepositoryImpl({required CaregiverApi api}) : _api = api;

  final CaregiverApi _api;

  @override
  Future<List<AppNotification>> fetchNotifications() async {
    final response = await _api.getNotifications();
    return response.data.map(notificationItemToAppNotification).toList();
  }

  @override
  Future<int> getUnreadCount() => _api.getNotificationsUnreadCount();

  @override
  Future<void> markRead(String id) {
    return _api.markNotificationRead(int.parse(id));
  }

  @override
  Future<void> markAllRead() async {
    await _api.markAllNotificationsRead();
  }

  @override
  Future<void> deleteNotification(String id) {
    return _api.deleteNotification(int.parse(id));
  }
}
