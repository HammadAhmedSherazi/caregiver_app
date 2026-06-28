import 'package:flutter/material.dart';

import '../../../core/di/service_locator.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/notification_model.dart';
import '../../../data/repositories/notification_repository.dart';
import '../../task/widgets/task_screen_header.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/loading_widget.dart';
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
  String? _error;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
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
        _error = 'Unable to load notifications.';
        _isLoading = false;
      });
    }
  }

  int get _newCount =>
      _notifications?.where((item) => !item.isRead).length ?? 0;

  void _removeNotification(String id) {
    setState(() {
      _notifications = _notifications
          ?.where((notification) => notification.id != id)
          .toList();
    });
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
            subtitle: _isLoading
                ? 'Loading alerts...'
                : '$_newCount new alerts',
            height: 171,
            onBack: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const LoadingWidget(message: 'Loading notifications...');
    }

    if (_error != null) {
      return ErrorDisplayWidget(onRetry: _load);
    }

    final items = _notifications ?? [];
    if (items.isEmpty) {
      return const Center(
        child: Text('No notifications'),
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
