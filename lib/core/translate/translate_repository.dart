/// EN ↔ ES translation for notes/comments (view-only; originals never mutated).
class TranslateRequest {
  const TranslateRequest({
    required this.text,
    required this.targetLocale,
    this.sourceLocale,
  });

  final String text;
  final String targetLocale;
  final String? sourceLocale;
}

class TranslateResult {
  const TranslateResult({
    required this.translatedText,
    required this.targetLocale,
    this.detectedSource,
    this.provider = 'unknown',
    this.cached = false,
  });

  final String translatedText;
  final String targetLocale;
  final String? detectedSource;
  final String provider;
  final bool cached;
}

class TranslateException implements Exception {
  const TranslateException(this.code, this.message);

  final String code;
  final String message;

  bool get isNotConfigured => code == 'TRANSLATION_NOT_CONFIGURED';

  factory TranslateException.fromFunctionResponse({required int status, required Object? data}) {
    if (data is Map) {
      final code = data['error']?.toString() ?? 'translate_failed';
      final message = data['message']?.toString() ?? 'Translation failed ($status)';
      return TranslateException(code, message);
    }
    return TranslateException('translate_failed', 'Translation failed ($status)');
  }

  @override
  String toString() => 'TranslateException($code): $message';
}

abstract class TranslateRepository {
  Future<TranslateResult> translate(TranslateRequest request);
}

class MockTranslateRepository implements TranslateRepository {
  MockTranslateRepository({this.failWith});

  TranslateException? failWith;
  final List<TranslateRequest> calls = [];

  @override
  Future<TranslateResult> translate(TranslateRequest request) async {
    calls.add(request);
    final failure = failWith;
    if (failure != null) throw failure;
    final prefix = request.targetLocale == 'es' ? '[ES] ' : '[EN] ';
    return TranslateResult(
      translatedText: '$prefix${request.text}',
      targetLocale: request.targetLocale,
      detectedSource: request.sourceLocale,
      provider: 'mock',
    );
  }
}
