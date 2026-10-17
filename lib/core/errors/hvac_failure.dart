/// Domain-level failures surfaced to users (never raw exceptions).
sealed class HvacFailure implements Exception {
  const HvacFailure(this.message);

  final String message;

  bool get isRetryable;

  @override
  String toString() => message;
}

class NetworkFailure extends HvacFailure {
  const NetworkFailure([super.message = 'Connection problem. Check your network and try again.']);

  @override
  bool get isRetryable => true;
}

class UnauthorizedFailure extends HvacFailure {
  const UnauthorizedFailure([super.message = 'Your session expired. Sign in again.']);

  @override
  bool get isRetryable => false;
}

class ValidationFailure extends HvacFailure {
  const ValidationFailure(super.message);

  @override
  bool get isRetryable => false;
}

class NotFoundFailure extends HvacFailure {
  const NotFoundFailure([super.message = 'The requested item was not found.']);

  @override
  bool get isRetryable => false;
}

class ServerFailure extends HvacFailure {
  const ServerFailure([super.message = 'Something went wrong on our side. Try again shortly.']);

  @override
  bool get isRetryable => true;
}

class UnknownFailure extends HvacFailure {
  const UnknownFailure([super.message = 'Something went wrong. Try again.']);

  @override
  bool get isRetryable => true;
}
