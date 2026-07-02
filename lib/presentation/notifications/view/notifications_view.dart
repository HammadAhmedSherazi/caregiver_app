import 'package:flutter/material.dart';

import '../../../core/di/service_locator.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/notification_model.dart';
import '../../../data/repositories/notification_repository.dart';
import '../../task/widgets/task_screen_header.dart';
import '../../widgets/get_request_view.dart';
import '../../widgets/skeletons/api_tab_skeletons.dart';
import '../widgets/notification_card.dart';

/// Figma node `1:2736` — notifications inbox screen.
class NotificationsView extends StatefulWidget {
  const NotificationsView({super.key});

  @override
  State<NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<NotificationsView> {
  final _repository = sl<NotificationRepository>();
  List<AppNotification>? _notifications;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final items = await _repository.fetchNotifications();
      if (!mounted) return;
      setState(() {
        _notifications = items;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  int get _newCount =>
      _notifications?.where((item) => !item.isRead).length ?? 0;

  Future<void> _removeNotification(String id) async {
    try {
      await _repository.deleteNotification(id);
      if (!mounted) return;
      setState(() {
        _notifications = _notifications
            ?.where((notification) => notification.id != id)
            .toList();
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to delete notification.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.homeBackground,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TaskScreenHeader(
            title: 'Notifications',
            subtitle: _isLoading ? 'Loading alerts...' : '$_newCount new alerts',
            height: 171,
            onBack: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: GetRequestView(
              isLoading: _isLoading,
              hasError: _hasError,
              onRetry: _load,
              skeleton: const NotificationsListSkeleton(),
              child: _buildContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final items = _notifications ?? [];
    if (items.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        color: AppColors.homePrimary,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 120),
            Center(child: Text('No notifications')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.homePrimary,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        children: [
          for (final notification in items)
            NotificationCard(
              notification: notification,
              onDismissed: () => _removeNotification(notification.id),
            ),
        ],
      ),
    );
  }
}
