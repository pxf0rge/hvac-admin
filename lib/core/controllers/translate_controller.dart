import 'package:flutter/foundation.dart';
import 'package:hvac_admin/core/translate/translate_repository.dart';

/// In-memory cache of translations keyed by source text + target locale.
class TranslateController extends ChangeNotifier {
  TranslateController(this._repository);

  final TranslateRepository _repository;
  final Map<String, TranslateResult> _cache = {};
  final Set<String> _loading = {};
  final Map<String, String> _errors = {};

  bool isLoading(String cacheKey) => _loading.contains(cacheKey);
  String? errorFor(String cacheKey) => _errors[cacheKey];
  TranslateResult? cached(String cacheKey) => _cache[cacheKey];

  static String cacheKey({required String text, required String targetLocale}) =>
      '$targetLocale|${text.trim()}';

  Future<TranslateResult?> translate({
    required String text,
    required String targetLocale,
    String? sourceLocale,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;
    final key = cacheKey(text: trimmed, targetLocale: targetLocale);
    final hit = _cache[key];
    if (hit != null) return hit;

    _loading.add(key);
    _errors.remove(key);
    notifyListeners();
    try {
      final result = await _repository.translate(
        TranslateRequest(text: trimmed, targetLocale: targetLocale, sourceLocale: sourceLocale),
      );
      _cache[key] = result;
      return result;
    } on TranslateException catch (error) {
      _errors[key] = error.isNotConfigured
          ? 'Translation is not configured yet.'
          : error.message;
      return null;
    } catch (error, stack) {
      debugPrint('TranslateController.translate failed: $error\n$stack');
      _errors[key] = 'Translation failed.';
      return null;
    } finally {
      _loading.remove(key);
      notifyListeners();
    }
  }

  void clearError(String cacheKey) {
    if (_errors.remove(cacheKey) != null) notifyListeners();
  }
}
