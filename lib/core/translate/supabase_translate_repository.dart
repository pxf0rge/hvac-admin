import 'package:hvac_admin/core/translate/translate_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseTranslateRepository implements TranslateRepository {
  SupabaseTranslateRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<TranslateResult> translate(TranslateRequest request) async {
    try {
      final response = await _client.functions.invoke(
        'translate-text',
        body: {
          'text': request.text,
          'target_locale': request.targetLocale,
          if (request.sourceLocale != null) 'source_locale': request.sourceLocale,
        },
      );

      final status = response.status;
      final data = response.data;
      if (status >= 400) {
        throw TranslateException.fromFunctionResponse(status: status, data: data);
      }
      if (data is! Map) {
        throw const TranslateException('invalid_response', 'translate-text returned unexpected payload');
      }

      final translated = data['translated_text']?.toString() ?? '';
      if (translated.isEmpty) {
        throw const TranslateException('empty_translation', 'Provider returned empty translation');
      }

      return TranslateResult(
        translatedText: translated,
        targetLocale: data['target_locale']?.toString() ?? request.targetLocale,
        detectedSource: data['detected_source']?.toString(),
        provider: data['provider']?.toString() ?? 'unknown',
        cached: data['cached'] == true,
      );
    } on TranslateException {
      rethrow;
    } catch (error) {
      throw TranslateException('translate_failed', error.toString());
    }
  }
}
