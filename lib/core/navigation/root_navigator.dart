import 'package:flutter/widgets.dart';

/// Navigator of the root [MaterialApp].
///
/// Used to clear pushed pages (Profile, Inbox, …) when the session ends so
/// the login screen is not hidden underneath them.
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();
