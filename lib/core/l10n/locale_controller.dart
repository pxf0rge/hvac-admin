import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hvac_admin/core/l10n/admin_strings.dart';
import 'package:hvac_admin/core/l10n/app_locale.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Admin UI language. Independent of the technician field-app locale.
class LocaleController extends ChangeNotifier {
  LocaleController({SharedPreferences? prefs}) : _prefs = prefs;

  static const prefsKey = 'hvac_admin.locale';

  SharedPreferences? _prefs;
  AppLocale _locale = AppLocale.english;
  bool _loaded = false;

  AppLocale get locale => _locale;
  bool get isLoaded => _loaded;
  AdminStrings get strings => AdminStrings(_locale);
  Locale get flutterLocale => _locale.flutterLocale;

  Future<void> load() async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
      final code = _prefs!.getString(prefsKey);
      _locale = AppLocaleX.fromCode(code);
    } catch (error, stack) {
      debugPrint('LocaleController.load failed: $error\n$stack');
    } finally {
      _loaded = true;
      notifyListeners();
    }
  }

  Future<void> setLocale(AppLocale locale) async {
    if (_locale == locale) return;
    _locale = locale;
    notifyListeners();
    try {
      _prefs ??= await SharedPreferences.getInstance();
      await _prefs!.setString(prefsKey, locale.code);
    } catch (error, stack) {
      debugPrint('LocaleController.setLocale persist failed: $error\n$stack');
    }
  }
}
