import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/di/service_locator.dart';
import '../../../core/network/chat_realtime_service.dart';
import '../../../data/models/inbox_thread_model.dart';
import '../../../data/models/notification_model.dart';
import '../../../data/repositories/inbox_repository.dart';
import '../../../data/repositories/notification_repository.dart';
import '../../main/app_navigator.dart';
import '../../main/widgets/main_bottom_nav_bar.dart';
import '../../widgets/velora/velora.dart';
import 'chat_view.dart';

/// Inbox: alerts (`GET /notifications`) and conversations with the office
/// (`GET /conversations`, realtime refresh via [ChatRealtimeService]).
class InboxView extends StatefulWidget {
  const InboxView({super.key});

  @override
  State<InboxView> createState() => _InboxViewState();
}

class _InboxViewState extends State<InboxView> {
  final _inbox = sl<InboxRepository>();
  final _notifications = sl<NotificationRepository>();
  final _realtime = sl<ChatRealtimeService>();
  StreamSubscription<void>? _inboxUpdatesSub;

  List<InboxThread>? _threads;
  List<AppNotification>? _alerts;
  bool _threadsFailed = false;
  bool _alertsFailed = false;

  @override
  void initState() {
    super.initState();
    _load();
    _initRealtime();
  }

  @override
  void dispose() {
    _inboxUpdatesSub?.cancel();
    super.dispose();
  }

  Future<void> _initRealtime() async {
    try {
      await _realtime.connect();
      _inboxUpdatesSub = _realtime.inboxUpdates.listen((_) {
        if (mounted) _loadThreads();
      });
    } catch (_) {
      // REST + periodic unread polling remain the fallback.
    }
  }

  Future<void> _load() => Future.wait([_loadThreads(), _loadAlerts()]);

  Future<void> _loadThreads() async {
    try {
      final items = await _inbox.fetchThreads();
      if (!mounted) return;
      setState(() {
        _threads = items;
        _threadsFailed = false;
      });
    } catch (_) {
      if (!mounted) return;
      // Keep an existing list visible on background refresh failures.
      setState(() => _threadsFailed = _threads == null);
    }
  }

  Future<void> _loadAlerts() async {
    try {
      final items = await _notifications.fetchNotifications();
      if (!mounted) return;
      setState(() {
        _alerts = items;
        _alertsFailed = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _alertsFailed = _alerts == null);
    }
  }

  Future<void> _openThread(InboxThread thread) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => ChatView(thread: thread)),
    );
    if (!mounted) return;
    // Opening the chat marks it read — clear the unread style on return.
    setState(() {
      _threads = [
        for (final t in _threads ?? const <InboxThread>[])
          t.id == thread.id ? t.copyWith(isUnread: false) : t,
      ];
    });
  }

  Future<void> _openAlert(AppNotification alert) async {
    if (!alert.isRead) {
      setState(() {
        _alerts = [
          for (final a in _alerts ?? const <AppNotification>[])
            a.id == alert.id ? a.copyWith(isRead: true) : a,
        ];
      });
      unawaited(_notifications.markRead(alert.id).catchError((_) {}));
    }
    switch (alert.kind) {
      case NotificationKind.schedule:
        AppNavigator.goToTab(context, MainTab.time);
      case NotificationKind.compliance:
        AppNavigator.goToTab(context, MainTab.checkIn);
      case NotificationKind.message:
        break;
    }
  }

  Future<void> _deleteAlert(AppNotification alert) async {
    final previous = _alerts;
    setState(() => _alerts = _alerts?.where((a) => a.id != alert.id).toList());
    try {
      await _notifications.deleteNotification(alert.id);
    } catch (_) {
      if (!mounted) return;
      setState(() => _alerts = previous);
      showVeloraToast(context, 'Unable to delete that alert.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final alerts = _alerts;
    final threads = _threads;

    return VeloraScaffold(
      body: VeloraPage(
        gap: 10,
        onRefresh: _load,
        header: VeloraHeader(
          title: 'Inbox',
          subtitle: 'Alerts and messages from the office',
          onBack: () => Navigator.of(context).pop(),
        ),
        children: [
          if (alerts == null && !_alertsFailed)
            const VeloraLoadingState()
          else if (_alertsFailed)
            VeloraErrorState(message: 'We couldn\'t load your alerts.', onRetry: _loadAlerts)
          else
            for (final alert in alerts!)
              Dismissible(
                key: ValueKey('alert-${alert.id}'),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  decoration: BoxDecoration(
                    color: VeloraColors.dangerBg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text('Delete',
                      style: VeloraText.body(13, weight: FontWeight.w700, color: VeloraColors.dangerText)),
                ),
                onDismissed: (_) => _deleteAlert(alert),
                child: _AlertCard(alert: alert, onTap: () => _openAlert(alert)),
              ),
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 2),
            child: Text(
              'MESSAGES WITH THE OFFICE',
              textAlign: TextAlign.center,
              style: VeloraText.caption,
            ),
          ),
          if (threads == null && !_threadsFailed)
            const VeloraLoadingState()
          else if (_threadsFailed)
            VeloraErrorState(message: 'We couldn\'t load your messages.', onRetry: _loadThreads)
          else if (threads!.isEmpty)
            const VeloraEmptyState(
              title: 'No messages yet',
              message: 'Conversations with the office will show here.',
              icon: VeloraIcons.message,
            )
          else
            for (final thread in threads)
              _ThreadCard(thread: thread, onTap: () => _openThread(thread)),
        ],
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({required this.alert, required this.onTap});

  final AppNotification alert;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (icon, tone, tag, tagColor) = switch (alert.kind) {
      NotificationKind.schedule =>
        (VeloraIcons.clock, IconTileTone.amber, 'Time', VeloraColors.warnText),
      NotificationKind.compliance =>
        (VeloraIcons.clipboardCheck, IconTileTone.good, 'Check-in', VeloraColors.goodText),
      NotificationKind.message =>
        (VeloraIcons.message, IconTileTone.mint, 'Message', VeloraColors.teal),
    };

    return _InboxCard(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconTile(icon, tone: tone, size: 38, iconSize: 18, radius: 11),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${tag.toUpperCase()}${alert.isRead ? '' : ' · NEW'}',
                        style: VeloraText.body(10.5,
                            weight: FontWeight.w700, color: tagColor, letterSpacing: 0.6),
                      ),
                    ),
                    Text(alert.timestampLabel, style: VeloraText.body(11.5, color: VeloraColors.muted)),
                  ],
                ),
                const SizedBox(height: 3),
                Text(alert.title, style: VeloraText.body(14, weight: FontWeight.w700)),
                if (alert.body.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(alert.body, style: VeloraText.body(13, color: VeloraColors.muted, height: 1.4)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ThreadCard extends StatelessWidget {
  const _ThreadCard({required this.thread, required this.onTap});

  final InboxThread thread;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _InboxCard(
      onTap: onTap,
      child: Row(
        children: [
          const IconTile(VeloraIcons.message, size: 38, iconSize: 18, radius: 11),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        thread.contactName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: VeloraText.body(14, weight: FontWeight.w700),
                      ),
                    ),
                    Text(thread.timestampLabel, style: VeloraText.body(11.5, color: VeloraColors.muted)),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  thread.preview,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: VeloraText.body(
                    13,
                    weight: thread.isUnread ? FontWeight.w700 : FontWeight.w400,
                    color: thread.isUnread ? VeloraColors.ink : VeloraColors.muted,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          if (thread.isUnread) ...[
            const SizedBox(width: 10),
            Container(
              width: 9,
              height: 9,
              decoration: const BoxDecoration(color: VeloraColors.amber, shape: BoxShape.circle),
            ),
          ],
        ],
      ),
    );
  }
}

class _InboxCard extends StatelessWidget {
  const _InboxCard({required this.child, required this.onTap});

  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: VeloraColors.line),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: child,
        ),
      ),
    );
  }
}
