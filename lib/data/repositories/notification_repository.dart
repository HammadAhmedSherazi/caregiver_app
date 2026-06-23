import '../models/notification_model.dart';

abstract class NotificationRepository {
  Future<List<AppNotification>> fetchNotifications();
}

class NotificationRepositoryImpl implements NotificationRepository {
  static const _seed = [
    AppNotification(
      id: '1',
      title: 'Schedule updated',
      body: 'Your morning visit with Barbara has been moved to 10:00 AM.',
      timestampLabel: '2h ago',
      kind: NotificationKind.schedule,
    ),
    AppNotification(
      id: '2',
      title: 'Compliance form due Friday',
      body: 'May 2026 compliance form is due by end of day Friday.',
      timestampLabel: '5h ago',
      kind: NotificationKind.compliance,
    ),
    AppNotification(
      id: '3',
      title: 'New message from coordinator',
      body: 'Please review the updated care plan for your afternoon shift.',
      timestampLabel: 'Yesterday',
      kind: NotificationKind.message,
      isRead: true,
    ),
  ];

  @override
  Future<List<AppNotification>> fetchNotifications() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return List<AppNotification>.from(_seed);
  }
}
