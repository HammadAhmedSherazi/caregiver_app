import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/di/service_locator.dart';
import '../../../core/network/chat_realtime_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/inbox_thread_model.dart';
import '../../../data/repositories/inbox_repository.dart';
import '../../task/widgets/task_screen_header.dart';
import '../../widgets/get_request_view.dart';
import '../../widgets/skeletons/api_tab_skeletons.dart';
import '../widgets/inbox_thread_card.dart';
import 'chat_view.dart';

/// Figma node `1:2685` — inbox thread list.
class InboxView extends StatefulWidget {
  const InboxView({super.key});

  @override
  State<InboxView> createState() => _InboxViewState();
}

class _InboxViewState extends State<InboxView> {
  final _repository = sl<InboxRepository>();
  final _realtime = sl<ChatRealtimeService>();
  StreamSubscription<void>? _inboxUpdatesSub;
  List<InboxThread>? _threads;
  bool _isLoading = true;
  bool _hasError = false;

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
        if (!mounted) return;
        _load();
      });
    } catch (_) {
      // REST + periodic unread polling remain the fallback.
    }
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final items = await _repository.fetchThreads();
      if (!mounted) return;
      setState(() {
        _threads = items;
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

  void _openThread(InboxThread thread) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChatView(thread: thread),
      ),
    );
  }

  void _removeThread(String id) {
    setState(() {
      _threads = _threads?.where((thread) => thread.id != id).toList();
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
            title: 'Inbox',
            subtitle: 'Assigned to you',
            height: 171,
            onBack: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: GetRequestView(
              isLoading: _isLoading,
              hasError: _hasError,
              onRetry: _load,
              skeleton: const InboxListSkeleton(),
              child: _buildContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final items = _threads ?? [];
    if (items.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        color: AppColors.homePrimary,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 120),
            Center(child: Text('No messages')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.homePrimary,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        children: [
          for (final thread in items)
            InboxThreadCard(
              thread: thread,
              onTap: () => _openThread(thread),
              onDismissed: () => _removeThread(thread.id),
            ),
        ],
      ),
    );
  }
}
