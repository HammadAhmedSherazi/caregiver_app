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

  /// Broadcasting auth is **not** under `/api`.
  static const String broadcastingAuthUrl = String.fromEnvironment(
    'BROADCASTING_AUTH_URL',
    defaultValue: 'https://beydountech.com/broadcasting/auth',
  );

  /// Laravel Reverb app key. Override via `--dart-define=REVERB_APP_KEY=...`.
  static const String reverbAppKey = String.fromEnvironment(
    'REVERB_APP_KEY',
    defaultValue: '0f8d5707fa17de4e15ce',
  );

  static const String reverbHost = String.fromEnvironment(
    'REVERB_HOST',
    defaultValue: 'beydountech.com',
  );

  static const int reverbPort = int.fromEnvironment(
    'REVERB_PORT',
    defaultValue: 443,
  );

  /// Laravel `.env` uses `https`/`http`; [reverbUseTls] maps that for the client.
  static const String _reverbSchemeEnv = String.fromEnvironment(
    'REVERB_SCHEME',
    defaultValue: 'https',
  );

  static bool get reverbUseTls {
    switch (_reverbSchemeEnv.toLowerCase()) {
      case 'http':
      case 'ws':
        return false;
      case 'https':
      case 'wss':
      default:
        return true;
    }
  }

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
