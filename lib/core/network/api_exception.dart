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

class ValidationException extends ApiException {
  ValidationException(super.message) : super(statusCode: 422);
}
