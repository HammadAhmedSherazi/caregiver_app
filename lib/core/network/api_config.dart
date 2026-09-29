/// API configuration.
///
/// Set the base URL via `--dart-define=API_BASE_URL=https://your-domain.com/api`
/// or replace [defaultBaseUrl] before building.
class ApiConfig {
  ApiConfig._();

  static const String defaultBaseUrl = 'https://beydountech.com/api';

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: defaultBaseUrl,
  );

  // Chat socket (Laravel Reverb). The app key, auth endpoint, channels and
  // `enabled` come from `GET /realtime/config`; the socket itself is always
  // reached at [socketHost] over TLS (wss, 443). The `REVERB_*` defines are
  // optional local-debug overrides.
  static const String defaultSocketHost = 'chat.beydountech.com';
  static const String socketHost = String.fromEnvironment('REVERB_HOST', defaultValue: defaultSocketHost);
  static const int socketPort = int.fromEnvironment('REVERB_PORT', defaultValue: 443);
  static const String reverbAppKeyOverride = String.fromEnvironment('REVERB_APP_KEY');
  static const String broadcastingAuthUrlOverride = String.fromEnvironment('BROADCASTING_AUTH_URL');

  /// Open chats poll `GET /conversations/{id}` at this rate while the socket
  /// is not live.
  static const Duration chatPollInterval = Duration(seconds: 10);

  /// After a failed socket connect, stay on REST this long before retrying,
  /// so a 404 socket path can't loop connect → disconnect → reconnect.
  static const Duration realtimeRetryCooldown = Duration(minutes: 2);

  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  /// Default page size for paginated GET endpoints (`/visits`, `/schedule`).
  static const int defaultPerPage = 10;

  /// Pay endpoint returns more rows per page by default.
  static const int payPerPage = 50;

  /// Enables the VELORA contract endpoints from `MOBILE_API_VELORA.md`.
  ///
  /// Those endpoints are **PLANNED — NOT LIVE**. Keep this `false` (default)
  /// until the backend ships them; enable per build with
  /// `--dart-define=VELORA_API=true`. While disabled, every planned
  /// repository call throws [ApiNotLiveException] instead of hitting a URL
  /// that does not exist, and screens keep using the live API only.
  static const bool veloraApiEnabled = bool.fromEnvironment(
    'VELORA_API',
    defaultValue: false,
  );

  /// Languages the server localizes `*_label` strings and pushes into.
  static const List<String> supportedLanguages = ['en', 'ar'];

  static const Map<String, String> defaultHeaders = {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };
}
