import 'package:dio/dio.dart';

import '../../data/local/session_storage.dart';
import '../../data/local/token_storage.dart';
import '../utils/helpers/logger.dart';
import 'api_config.dart';
import 'api_exception.dart';
import 'session_expired_notifier.dart';
import 'token_refresh_handler.dart';

class ApiClient {
  ApiClient({
    required this._tokenStorage,
    required this._sessionStorage,
    required this._sessionExpiredNotifier,
    required this._tokenRefreshHandler,
  })  : _dio = Dio(
          BaseOptions(
            baseUrl: ApiConfig.baseUrl,
            connectTimeout: ApiConfig.connectTimeout,
            receiveTimeout: ApiConfig.receiveTimeout,
            headers: ApiConfig.defaultHeaders,
          ),
        ) {
    _dio.interceptors.add(_ApiLoggingInterceptor());
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _tokenStorage.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          final retried = await _tryRefreshAndRetry(error, handler);
          if (retried) return;

          await _handleUnauthorizedIfNeeded(error);
          handler.reject(_wrapError(error));
        },
      ),
    );
  }

  final TokenStorage _tokenStorage;
  final SessionStorage _sessionStorage;
  final SessionExpiredNotifier _sessionExpiredNotifier;
  final TokenRefreshHandler _tokenRefreshHandler;
  final Dio _dio;
  bool _isHandlingUnauthorized = false;

  Future<bool> _tryRefreshAndRetry(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    if (error.response?.statusCode != 401) return false;
    if (_shouldSkipAuthRecovery(error.requestOptions.path)) return false;
    if (error.requestOptions.extra['_authRetried'] == true) return false;

    final refreshed = await _tokenRefreshHandler.tryRefresh();
    if (!refreshed) return false;

    try {
      final options = error.requestOptions;
      options.extra['_authRetried'] = true;
      final token = await _tokenStorage.getToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      final response = await _dio.fetch<dynamic>(options);
      handler.resolve(response);
      return true;
    } catch (_) {
      return false;
    }
  }

  bool _shouldSkipAuthRecovery(String path) {
    return path.endsWith('/login') || path.endsWith('/refresh');
  }

  Future<void> _handleUnauthorizedIfNeeded(DioException error) async {
    if (error.response?.statusCode != 401) return;
    if (_isPublicAuthRequest(error.requestOptions.path)) return;
    if (_isHandlingUnauthorized) return;

    _isHandlingUnauthorized = true;
    try {
      await _tokenStorage.clearToken();
      await _sessionStorage.clearUser();
      _sessionExpiredNotifier.notify();
    } finally {
      _isHandlingUnauthorized = false;
    }
  }

  bool _isPublicAuthRequest(String path) {
    return path.endsWith('/login') || path.endsWith('/refresh');
  }

  Dio get dio => _dio;

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response<T>> delete<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.delete<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response<T>> postMultipart<T>(
    String path, {
    required FormData data,
  }) {
    return _dio.post<T>(
      path,
      data: data,
      options: Options(contentType: 'multipart/form-data'),
    );
  }

  Future<Response<List<int>>> downloadBytes(String path) async {
    final response = await _dio.get<List<int>>(
      path,
      options: Options(responseType: ResponseType.bytes),
    );
    return response;
  }

  DioException _wrapError(DioException error) {
    final response = error.response;
    final statusCode = response?.statusCode;
    final message = _extractMessage(response?.data) ??
        error.message ??
        'Request failed';

    switch (statusCode) {
      case 401:
        return DioException(
          requestOptions: error.requestOptions,
          response: response,
          type: error.type,
          error: UnauthorizedException(message),
        );
      case 409:
        return DioException(
          requestOptions: error.requestOptions,
          response: response,
          type: error.type,
          error: ConflictException(message),
        );
      case 403:
        return DioException(
          requestOptions: error.requestOptions,
          response: response,
          type: error.type,
          error: ForbiddenException(message),
        );
      case 404:
        return DioException(
          requestOptions: error.requestOptions,
          response: response,
          type: error.type,
          error: NotFoundException(message),
        );
      case 422:
        return DioException(
          requestOptions: error.requestOptions,
          response: response,
          type: error.type,
          error: ValidationException(message),
        );
      default:
        return DioException(
          requestOptions: error.requestOptions,
          response: response,
          type: error.type,
          error: ApiException(message, statusCode: statusCode),
        );
    }
  }

  String? _extractMessage(Object? data) {
    if (data is Map<String, dynamic>) {
      final message = data['message'];
      if (message is String && message.isNotEmpty) {
        return message;
      }
    }
    return null;
  }

  static Never rethrowAsApiException(Object error) {
    if (error is DioException) {
      final wrapped = error.error;
      if (wrapped is ApiException) throw wrapped;
      throw ApiException(error.message ?? 'Network request failed');
    }
    if (error is ApiException) throw error;
    throw ApiException(error.toString());
  }
}

class _ApiLoggingInterceptor extends Interceptor {
  static const _tag = 'API';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final query = options.uri.query.isNotEmpty ? '?${options.uri.query}' : '';
    AppLogger.info(
      '→ ${options.method} ${options.path}$query',
      tag: _tag,
    );

    if (options.data != null) {
      AppLogger.debug(
        'Request body: ${_formatPayload(options.data)}',
        tag: _tag,
      );
    }

    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    final request = response.requestOptions;
    AppLogger.info(
      '✓ SUCCESS ${response.statusCode} ${request.method} ${request.path}',
      tag: _tag,
    );
    AppLogger.debug(
      'Response body: ${_formatPayload(response.data)}',
      tag: _tag,
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final request = err.requestOptions;
    final statusCode = err.response?.statusCode;
    final apiMessage = _extractLogMessage(err.response?.data) ?? err.message;

    AppLogger.error(
      '✗ FAILED ${statusCode ?? 'NETWORK'} ${request.method} ${request.path}',
      tag: _tag,
      error: apiMessage,
    );

    if (err.response?.data != null) {
      AppLogger.debug(
        'Error body: ${_formatPayload(err.response!.data)}',
        tag: _tag,
      );
    }

    handler.next(err);
  }

  String _formatPayload(Object? data) {
    if (data == null) return 'null';
    if (data is List<int>) {
      return '<binary ${data.length} bytes>';
    }
    if (data is Map<String, dynamic>) {
      return _sanitizeMap(data).toString();
    }
    if (data is List) {
      return data.toString();
    }
    return data.toString();
  }

  Map<String, dynamic> _sanitizeMap(Map<String, dynamic> data) {
    final sanitized = <String, dynamic>{};
    for (final entry in data.entries) {
      final key = entry.key.toLowerCase();
      if (key == 'password' ||
          key == 'token' ||
          key == 'authorization' ||
          key.contains('secret')) {
        sanitized[entry.key] = '***';
      } else if (entry.value is Map<String, dynamic>) {
        sanitized[entry.key] =
            _sanitizeMap(entry.value as Map<String, dynamic>);
      } else {
        sanitized[entry.key] = entry.value;
      }
    }
    return sanitized;
  }

  String? _extractLogMessage(Object? data) {
    if (data is Map<String, dynamic>) {
      final message = data['message'];
      if (message is String && message.isNotEmpty) {
        return message;
      }
    }
    return null;
  }
}
