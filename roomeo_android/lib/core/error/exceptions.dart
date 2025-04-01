// lib/core/error/exceptions.dart

class AppException implements Exception {
  final String message;

  AppException(this.message);

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  NetworkException(String message) : super(message);
}

class AuthException extends AppException {
  AuthException(String message) : super(message);
}

class NotFoundException extends AppException {
  NotFoundException(String message) : super(message);
}

class ValidationException extends AppException {
  ValidationException(String message) : super(message);
}

class ConflictException extends AppException {
  ConflictException(String message) : super(message);
}

class ForbiddenException extends AppException {
  ForbiddenException(String message) : super(message);
}
