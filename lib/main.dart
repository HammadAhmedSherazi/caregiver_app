import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'core/di/service_locator.dart';
import 'core/push/firebase_push_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Portrait only, on phones and tablets (also set natively so the launch
  // screen doesn't rotate).
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await setupServiceLocator();
  // Firebase push; a failure only turns push off.
  await sl<FirebasePushService>().initialize();
  runApp(const App());
}
