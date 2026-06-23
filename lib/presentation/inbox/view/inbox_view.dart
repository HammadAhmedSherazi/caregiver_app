import 'package:flutter/material.dart';

import '../../../core/di/service_locator.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/inbox_thread_model.dart';
import '../../../data/repositories/inbox_repository.dart';
import '../../task/widgets/task_screen_header.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/loading_widget.dart';
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
  List<InboxThread>? _threads;
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
      final items = await _repository.fetchThreads();
      if (!mounted) return;
      setState(() {
        _threads = items;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Unable to load inbox.';
        _isLoading = false;
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
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const LoadingWidget(message: 'Loading inbox...');
    }

    if (_error != null) {
      return ErrorDisplayWidget(message: _error!, onRetry: _load);
    }

    final items = _threads ?? [];
    if (items.isEmpty) {
      return const Center(child: Text('No messages'));
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
