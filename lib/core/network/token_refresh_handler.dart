typedef TokenRefreshCallback = Future<bool> Function();

class TokenRefreshHandler {
  TokenRefreshCallback? onRefresh;

  Future<bool> tryRefresh() async {
    final callback = onRefresh;
    if (callback == null) return false;
    return callback();
  }
}
