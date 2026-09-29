import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/service_locator.dart';
import '../../../core/network/api_config.dart';
import '../../../core/network/chat_realtime_service.dart';
import '../../../core/utils/helpers/phone_launch_helper.dart';
import '../../../data/models/api/velora/velora_models.dart';
import '../../../data/models/chat_message_model.dart';
import '../../../data/models/inbox_thread_model.dart';
import '../../../data/models/notification_model.dart';
import '../../../data/repositories/inbox_repository.dart';
import '../../../data/repositories/notification_repository.dart';
import '../../main/app_action_router.dart';
import '../../main/app_navigator.dart';
import '../../main/widgets/main_bottom_nav_bar.dart';
import '../../widgets/velora/velora.dart';
import '../cubit/chat_cubit.dart';
import '../cubit/chat_state.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/chat_input_bar.dart';
import 'chat_view.dart';
import '../../../core/i18n/tr.dart';

/// Inbox (design `Inbox.dc.html`): alerts that need you
/// (`GET /notifications`), then the one chat with the office inline, with
/// the composer pinned at the bottom.
///
/// The office thread is `GET /inbox/office-thread` (🚧 planned, used when
/// `ApiConfig.veloraApiEnabled`); until then the most recent
/// `/conversations` thread plays that part. Messages, sending and realtime
/// use the existing `/conversations/{id}` endpoints through [ChatCubit].
class InboxView extends StatefulWidget {
  const InboxView({super.key});

  @override
  State<InboxView> createState() => _InboxViewState();
}

class _InboxViewState extends State<InboxView> {
  final _inbox = sl<InboxRepository>();
  final _notifications = sl<NotificationRepository>();
  final _realtime = sl<ChatRealtimeService>();
  final _scroll = ScrollController();
  final _composer = TextEditingController();
  final _messagesKey = GlobalKey();
  StreamSubscription<void>? _inboxUpdatesSub;

  List<AppNotification>? _alerts;
  bool _alertsFailed = false;

  /// Inline office conversation; null until the thread is known.
  ChatCubit? _chat;
  OfficeThreadModel? _office;
  String? _officeName;
  List<InboxThread> _otherThreads = const [];
  bool _threadsLoaded = false;
  bool _threadsFailed = false;

  @override
  void initState() {
    super.initState();
    _load();
    _initRealtime();
  }

  @override
  void dispose() {
    _inboxUpdatesSub?.cancel();
    _chat?.close();
    _scroll.dispose();
    _composer.dispose();
    super.dispose();
  }

  Future<void> _initRealtime() async {
    // Listen first: while the socket is not live, inboxUpdates is fed by the
    // service's unread-count polling, so the list still refreshes.
    _inboxUpdatesSub = _realtime.inboxUpdates.listen((_) {
      if (mounted) _loadThreads();
    });
    try {
      await _realtime.connect();
    } catch (_) {
      // Socket not live (RealtimeUnavailableException) or failed: REST only.
    }
  }

  Future<void> _load() async {
    await Future.wait([_loadThreads(), _loadAlerts()]);
    final chat = _chat;
    if (chat != null && chat.state.hasError) await chat.load();
  }

  // ------------------------------------------------------------ data

  Future<void> _loadThreads() async {
    OfficeThreadModel? office = _office;
    if (office == null && ApiConfig.veloraApiEnabled) {
      try {
        office = await _inbox.getOfficeThread();
      } catch (_) {
        // Not live yet: fall back to the conversations list.
      }
    }

    List<InboxThread>? threads;
    try {
      threads = await _inbox.fetchThreads();
    } catch (_) {
      if (!mounted) return;
      if (office == null) {
        // Keep an existing thread visible on background refresh failures.
        setState(() => _threadsFailed = !_threadsLoaded);
        return;
      }
    }
    if (!mounted) return;

    final officeId = (office != null && office.threadId > 0)
        ? office.threadId.toString()
        : (_chat?.threadId ?? threads?.firstOrNull?.id);
    final officeThread = threads?.where((t) => t.id == officeId).firstOrNull;

    setState(() {
      _office = office;
      _officeName = office?.officeName.isNotEmpty == true
          ? office!.officeName
          : (officeThread?.contactName ?? _officeName);
      if (threads != null) {
        _otherThreads = threads.where((t) => t.id != officeId).toList();
      }
      _threadsLoaded = true;
      _threadsFailed = false;
    });

    if (officeId != null && _chat?.threadId != officeId) {
      await _chat?.close();
      if (!mounted) return;
      setState(() {
        _chat = ChatCubit(
          threadId: officeId,
          repository: _inbox,
          realtime: _realtime,
        )..start();
      });
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

  // ------------------------------------------------------------ actions

  Future<void> _send() async {
    final chat = _chat;
    final text = _composer.text.trim();
    if (chat == null || text.isEmpty) return;
    _composer.clear();
    await chat.sendMessage(text);
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  void _scrollToMessages() {
    final target = _messagesKey.currentContext;
    if (target != null) {
      Scrollable.ensureVisible(
        target,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      _scrollToEnd();
    }
  }

  Future<void> _callOffice() async {
    var phone = _office?.officePhone;
    if ((phone == null || phone.isEmpty) && ApiConfig.veloraApiEnabled) {
      // The office thread may have failed to load earlier — try once more.
      try {
        final office = await _inbox.getOfficeThread();
        if (mounted) setState(() => _office = office);
        phone = office.officePhone;
      } catch (_) {}
    }
    if (!mounted) return;
    if (phone == null || phone.isEmpty) {
      showVeloraToast(context, tr('The office number isn\'t available yet. Send a message below.'));
      _scrollToMessages();
      return;
    }
    final ok = await launchPhoneCall(phone);
    if (!ok && mounted) showVeloraToast(context, tr('Unable to start a call.'));
  }

  /// Opens a conversation other than the office one. The realtime service
  /// holds a single conversation, so the inline chat pauses meanwhile.
  Future<void> _openThread(InboxThread thread) async {
    await _chat?.pause();
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => ChatView(thread: thread)),
    );
    if (!mounted) return;
    // Opening the chat marks it read — clear the unread style on return.
    setState(() {
      _otherThreads = [
        for (final t in _otherThreads) t.id == thread.id ? t.copyWith(isUnread: false) : t,
      ];
    });
    await _chat?.resume();
  }

  /// Alert tap: the server `action` deep link wins; otherwise the design's
  /// links by category (Time → Fix a clock-out / Time, Documents → Upload,
  /// Pay → Paystub / Pay, Check-in → Check-in, Message → the chat below).
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

    final action = alert.action;
    if (action != null && action.screen != AppScreen.inbox) {
      if (await AppActionRouter.open(context, action)) return;
    }
    if (!mounted) return;

    switch (_AlertCategory.of(alert)) {
      case _AlertCategory.time:
        AppNavigator.goToTab(context, MainTab.time);
      case _AlertCategory.documents:
        await AppNavigator.openUpload(context);
      case _AlertCategory.pay:
        AppNavigator.goToTab(context, MainTab.pay);
      case _AlertCategory.checkIn:
        AppNavigator.goToTab(context, MainTab.checkIn);
      case _AlertCategory.message:
        _scrollToMessages();
      case _AlertCategory.other:
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
      showVeloraToast(context, tr('Unable to delete that alert.'));
    }
  }

  // ------------------------------------------------------------ build

  @override
  Widget build(BuildContext context) {
    final chat = _chat;

    Widget body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        VeloraHeader(
          title: tr('Inbox'),
          subtitle: _officeName ?? tr('Alerts and messages from the office'),
          onBack: () => Navigator.of(context).pop(),
          trailing: HeaderSquareButton(
            icon: VeloraIcons.phone,
            semanticLabel: tr('Call the office'),
            background: VeloraColors.amber,
            foreground: const Color(0xFF3A2A06),
            onTap: _callOffice,
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            color: VeloraColors.teal,
            onRefresh: _load,
            child: _buildList(),
          ),
        ),
        if (chat == null)
          ChatInputBar(controller: _composer, onSend: _send, enabled: false)
        else
          BlocBuilder<ChatCubit, ChatState>(
            bloc: chat,
            buildWhen: (a, b) => a.status != b.status,
            builder: (context, state) => ChatInputBar(
              controller: _composer,
              onSend: _send,
              enabled: !state.isLoading && !state.hasError,
            ),
          ),
      ],
    );

    if (chat != null) {
      body = BlocListener<ChatCubit, ChatState>(
        bloc: chat,
        // New or sent messages only — not the first load, so the alerts
        // stay in view when the page opens.
        listenWhen: (previous, current) =>
            previous.status == ChatStatus.success &&
            (previous.messages.length != current.messages.length ||
                previous.messages.lastOrNull?.sendStatus != current.messages.lastOrNull?.sendStatus),
        listener: (_, _) => _scrollToEnd(),
        child: body,
      );
    }

    return Scaffold(
      backgroundColor: VeloraColors.background,
      body: body,
    );
  }

  Widget _buildList() {
    final alerts = _alerts;
    final chat = _chat;

    final children = <Widget>[
      if (alerts == null && !_alertsFailed)
        const VeloraLoadingState()
      else if (_alertsFailed)
        VeloraErrorState(message: tr('We couldn\'t load your alerts.'), onRetry: _loadAlerts)
      else
        for (final alert in alerts!)
          Dismissible(
            key: ValueKey('alert-${alert.id}'),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: AlignmentDirectional.centerEnd,
              padding: const EdgeInsetsDirectional.only(end: 20),
              decoration: BoxDecoration(
                color: VeloraColors.dangerBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(tr('Delete'),
                  style: VeloraText.body(13, weight: FontWeight.w700, color: VeloraColors.dangerText)),
            ),
            onDismissed: (_) => _deleteAlert(alert),
            child: _AlertCard(alert: alert, onTap: () => _openAlert(alert)),
          ),
      for (final thread in _otherThreads)
        _ThreadCard(thread: thread, onTap: () => _openThread(thread)),
      Padding(
        key: _messagesKey,
        padding: const EdgeInsets.only(top: 10, bottom: 2),
        child: Text(
          tr('MESSAGES WITH THE OFFICE'),
          textAlign: TextAlign.center,
          style: VeloraText.body(11, weight: FontWeight.w700, color: VeloraColors.caption, letterSpacing: 1.1),
        ),
      ),
      if (chat != null)
        _OfficeMessages(chat: chat)
      else if (_threadsFailed)
        VeloraErrorState(message: tr('We couldn\'t load your messages.'), onRetry: _loadThreads)
      else if (!_threadsLoaded)
        const VeloraLoadingState()
      else
        VeloraEmptyState(
          title: tr('No messages yet'),
          message: tr('Conversations with the office will show here.'),
          icon: VeloraIcons.message,
        ),
    ];

    return ListView.separated(
      controller: _scroll,
      physics: const AlwaysScrollableScrollPhysics(),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      itemCount: children.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, index) => _Rise(index: index, child: children[index]),
    );
  }
}

/// Messages of the inline office thread.
class _OfficeMessages extends StatelessWidget {
  const _OfficeMessages({required this.chat});

  final ChatCubit chat;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChatCubit, ChatState>(
      bloc: chat,
      builder: (context, state) {
        if (state.hasError) {
          return VeloraErrorState(
            message: tr('We couldn\'t load your messages.'),
            onRetry: chat.load,
          );
        }
        if (state.status == ChatStatus.initial || (state.isLoading && state.messages.isEmpty)) {
          return const VeloraLoadingState();
        }
        if (state.messages.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              tr('Send the office a message below.'),
              textAlign: TextAlign.center,
              style: VeloraText.body(13, color: VeloraColors.muted),
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final message in state.messages)
              ChatBubble(
                key: ValueKey('msg-${message.id}'),
                message: message,
                onRetry: message.sendStatus == ChatMessageSendStatus.failed
                    ? () => chat.retryMessage(message.id)
                    : null,
              ),
          ],
        );
      },
    );
  }
}

/// Alert grouping used for the icon, tag and tap target. Prefers the VELORA
/// `category`; falls back to the legacy notification `type`.
enum _AlertCategory {
  time,
  documents,
  pay,
  checkIn,
  message,
  other;

  static _AlertCategory of(AppNotification alert) {
    switch (alert.category) {
      case 'time':
        return time;
      case 'documents':
        return documents;
      case 'pay':
        return pay;
      case 'check_in':
        return checkIn;
      case 'message':
        return message;
      case 'other':
        return other;
    }
    return switch (alert.kind) {
      NotificationKind.schedule => time,
      NotificationKind.compliance => checkIn,
      NotificationKind.message => message,
    };
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({required this.alert, required this.onTap});

  final AppNotification alert;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (icon, tone, tag, tagColor) = switch (_AlertCategory.of(alert)) {
      _AlertCategory.time => (VeloraIcons.clock, IconTileTone.amber, tr('Time'), VeloraColors.warnText),
      _AlertCategory.documents =>
        (VeloraIcons.idCard, IconTileTone.amber, tr('Documents'), VeloraColors.warnText),
      _AlertCategory.pay => (VeloraIcons.wallet, IconTileTone.mint, tr('Pay'), VeloraColors.teal),
      _AlertCategory.checkIn => (VeloraIcons.check, IconTileTone.good, tr('Check-in'), VeloraColors.goodText),
      _AlertCategory.message => (VeloraIcons.message, IconTileTone.mint, tr('Message'), VeloraColors.teal),
      _AlertCategory.other => (VeloraIcons.bell, IconTileTone.mute, tr('Office'), VeloraColors.muted),
    };

    return _InboxCard(
      onTap: onTap,
      highlighted: !alert.isRead,
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
                        '${tag.toUpperCase()}${alert.isRead ? '' : ' · ${tr('NEW')}'}',
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

/// A conversation other than the office one (opens [ChatView]).
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

/// `.msg` card: white, 16 radius, hairline border, soft shadow, press scale.
class _InboxCard extends StatefulWidget {
  const _InboxCard({required this.child, required this.onTap, this.highlighted = false});

  final Widget child;
  final VoidCallback onTap;

  /// Unread alerts get the design's mint outline.
  final bool highlighted;

  @override
  State<_InboxCard> createState() => _InboxCardState();
}

class _InboxCardState extends State<_InboxCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _pressed ? 0.985 : 1,
      duration: const Duration(milliseconds: 80),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: Color(0x0D0A1E1A), blurRadius: 2, offset: Offset(0, 1)),
          ],
        ),
        child: Material(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: widget.highlighted ? const Color(0xFFC4DBD3) : VeloraColors.line,
              width: widget.highlighted ? 1.4 : 1,
            ),
          ),
          child: InkWell(
            onTap: widget.onTap,
            onHighlightChanged: (v) => setState(() => _pressed = v),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}

/// The design's `rise` entrance: fade in and slide up 12px, staggered for
/// the first few rows. Skipped when the platform asks for reduced motion.
class _Rise extends StatelessWidget {
  const _Rise({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    final delay = switch (index) { 0 => 0, 1 => 50, 2 => 100, _ => 150 };
    const duration = 420;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: duration + delay),
      curve: Interval(delay / (duration + delay), 1, curve: const Cubic(.2, .7, .2, 1)),
      builder: (_, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(0, 12 * (1 - t)), child: child),
      ),
      child: child,
    );
  }
}
