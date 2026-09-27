class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class UnauthorizedException extends ApiException {
  UnauthorizedException([super.message = 'Session expired. Please sign in again.'])
      : super(statusCode: 401);
}

class ConflictException extends ApiException {
  ConflictException(super.message) : super(statusCode: 409);
}

class NotFoundException extends ApiException {
  NotFoundException(super.message) : super(statusCode: 404);
}

class ForbiddenException extends ApiException {
  ForbiddenException(super.message) : super(statusCode: 403);
}

/// `422` — carries the per-field messages from `"errors": { "field": [..] }`.
class ValidationException extends ApiException {
  ValidationException(super.message, {this.errors = const {}})
      : super(statusCode: 422);

  final Map<String, List<String>> errors;

  /// First message for [field], if the server sent one.
  String? errorFor(String field) {
    final list = errors[field];
    return (list == null || list.isEmpty) ? null : list.first;
  }
}

/// `429` — rate limited. [retryAfter] comes from the `Retry-After` header or
/// the `retry_after` body field (seconds).
class TooManyRequestsException extends ApiException {
  TooManyRequestsException(super.message, {this.retryAfter})
      : super(statusCode: 429);

  final Duration? retryAfter;
}

/// Thrown on the device, without any network call, when code tries to use an
/// endpoint from `MOBILE_API_VELORA.md` that is **PLANNED — NOT LIVE**
/// (see `ApiConfig.veloraApiEnabled`).
class ApiNotLiveException extends ApiException {
  ApiNotLiveException(this.endpoint)
      : super('$endpoint is not available yet (planned API, not live).');

  final String endpoint;
}

/// Client-side check of a request against the API contract failed; the
/// request was not sent.
class RequestValidationException extends ApiException {
  RequestValidationException(this.errors)
      : super(errors.values.expand((e) => e).first);

  final Map<String, List<String>> errors;
}

/// Maps an HTTP error response to the typed exceptions above.
ApiException mapApiError({
  required int? statusCode,
  required Object? data,
  Map<String, List<String>>? headers,
  String fallbackMessage = 'Request failed',
}) {
  final body = data is Map ? Map<String, dynamic>.from(data) : const <String, dynamic>{};
  final raw = body['message'];
  final message = raw is String && raw.isNotEmpty ? raw : fallbackMessage;

  switch (statusCode) {
    case 401:
      return UnauthorizedException(message);
    case 403:
      return ForbiddenException(message);
    case 404:
      return NotFoundException(message);
    case 409:
      return ConflictException(message);
    case 422:
      return ValidationException(message, errors: _parseErrors(body['errors']));
    case 429:
      return TooManyRequestsException(
        message,
        retryAfter: _parseRetryAfter(headers, body['retry_after']),
      );
    default:
      return ApiException(message, statusCode: statusCode);
  }
}

Map<String, List<String>> _parseErrors(Object? raw) {
  if (raw is! Map) return const {};
  final result = <String, List<String>>{};
  raw.forEach((key, value) {
    if (value is List) {
      result['$key'] = value.map((e) => '$e').toList();
    } else if (value != null) {
      result['$key'] = ['$value'];
    }
  });
  return result;
}

Duration? _parseRetryAfter(Map<String, List<String>>? headers, Object? body) {
  String? header;
  headers?.forEach((key, values) {
    if (key.toLowerCase() == 'retry-after' && values.isNotEmpty) header = values.first;
  });
  final seconds = int.tryParse(header ?? '') ?? (body is num ? body.toInt() : int.tryParse('$body'));
  return seconds == null ? null : Duration(seconds: seconds);
}
