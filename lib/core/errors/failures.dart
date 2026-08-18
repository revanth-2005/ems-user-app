// Core Failures — sealed hierarchy for typed error propagation
abstract class Failure {
  final String message;
  const Failure(this.message);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No internet connection. Please try again.']);
}

class ServerFailure extends Failure {
  final int? statusCode;
  const ServerFailure({String message = 'Server error. Please try again later.', this.statusCode})
      : super(message);
}

class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Session expired. Please sign in again.']);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Failed to read local data.']);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'An unexpected error occurred.']);
}
