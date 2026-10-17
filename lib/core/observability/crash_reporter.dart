/// Optional crash reporting hook for production (e.g. Sentry).
abstract class CrashReporter {
  void captureException(Object error, {StackTrace? stack, Map<String, Object?> context = const {}});

  void captureMessage(String message, {Map<String, Object?> context = const {}});
}

class NoopCrashReporter implements CrashReporter {
  const NoopCrashReporter();

  @override
  void captureException(Object error, {StackTrace? stack, Map<String, Object?> context = const {}}) {}

  @override
  void captureMessage(String message, {Map<String, Object?> context = const {}}) {}
}

abstract final class CrashReporting {
  static CrashReporter instance = const NoopCrashReporter();
}
