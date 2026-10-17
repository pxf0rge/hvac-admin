import 'package:flutter/foundation.dart';
import 'package:hvac_admin/core/audit/audit_redaction.dart';
import 'package:hvac_admin/core/observability/crash_reporter.dart';

/// Structured logging for admin app boot and critical flows.
class HvacLog {
  HvacLog._();

  static HvacLogSink sink = const _DebugPrintSink();

  static void info(String event, {Map<String, Object?> fields = const {}}) {
    sink.write('info', event, _sanitize(fields));
  }

  static void warn(String event, {Map<String, Object?> fields = const {}, Object? error}) {
    sink.write('warn', event, _sanitize({
      ...fields,
      if (error != null) 'error': error.toString(),
    }));
  }

  static void error(String event, {Map<String, Object?> fields = const {}, Object? error, StackTrace? stack}) {
    if (error != null) {
      CrashReporting.instance.captureException(error, stack: stack, context: {'event': event, ...fields});
    }
    sink.write('error', event, _sanitize({
      ...fields,
      if (error != null) 'error': error.toString(),
      if (stack != null) 'stack': stack.toString(),
    }));
  }

  static Map<String, Object?> _sanitize(Map<String, Object?> fields) =>
      AuditRedaction.sanitizeFields(fields);
}

abstract class HvacLogSink {
  const HvacLogSink();
  void write(String level, String event, Map<String, Object?> fields);
}

class _DebugPrintSink extends HvacLogSink {
  const _DebugPrintSink();

  @override
  void write(String level, String event, Map<String, Object?> fields) {
    final buffer = StringBuffer('[hvac-admin] $level $event');
    if (fields.isNotEmpty) {
      buffer.write(' ');
      buffer.write(fields.entries.map((e) => '${e.key}=${e.value}').join(' '));
    }
    debugPrint(buffer.toString());
  }
}

/// Captures log lines for tests.
class MemoryHvacLogSink extends HvacLogSink {
  final List<String> lines = [];

  @override
  void write(String level, String event, Map<String, Object?> fields) {
    lines.add('$level|$event|${fields.entries.map((e) => '${e.key}=${e.value}').join(',')}');
  }
}
