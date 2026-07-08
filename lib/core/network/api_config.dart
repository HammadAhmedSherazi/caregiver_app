/// API configuration.
///
/// Set the base URL via `--dart-define=API_BASE_URL=https://your-domain.com/api`
/// or replace [defaultBaseUrl] before building.
class ApiConfig {
  ApiConfig._();

  static const String defaultBaseUrl = 'https://www.beydountech.com/api';

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: defaultBaseUrl,
  );

  /// Origin without trailing `/api` — used for broadcasting auth.
  static String get originUrl {
    final normalized = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    if (normalized.endsWith('/api')) {
      return normalized.substring(0, normalized.length - 4);
    }
    return normalized;
  }

  static String get broadcastingAuthUrl => '$originUrl/broadcasting/auth';

  /// Laravel Reverb (Pusher protocol). Override with dart-defines when ready.
  static const String reverbAppKey = String.fromEnvironment(
    'REVERB_APP_KEY',
    defaultValue: 'local-key',
  );

  static const String reverbHost = String.fromEnvironment(
    'REVERB_HOST',
    defaultValue: 'www.beydountech.com',
  );

  static const int reverbPort = int.fromEnvironment(
    'REVERB_PORT',
    defaultValue: 443,
  );

  static const String reverbScheme = String.fromEnvironment(
    'REVERB_SCHEME',
    defaultValue: 'wss',
  );

  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  /// Default page size for paginated GET endpoints (`/visits`, `/schedule`).
  static const int defaultPerPage = 10;

  /// Pay endpoint returns more rows per page by default.
  static const int payPerPage = 50;

  static const Map<String, String> defaultHeaders = {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };
}
