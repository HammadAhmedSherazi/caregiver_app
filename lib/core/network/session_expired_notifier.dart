typedef SessionExpiredCallback = void Function();

class SessionExpiredNotifier {
  SessionExpiredCallback? onSessionExpired;

  void notify() {
    onSessionExpired?.call();
  }
}
