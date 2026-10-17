import 'package:flutter/material.dart';

enum AppLocale { english, spanish }

extension AppLocaleX on AppLocale {
  Locale get flutterLocale => switch (this) {
        AppLocale.english => const Locale('en'),
        AppLocale.spanish => const Locale('es'),
      };

  String get code => switch (this) {
        AppLocale.english => 'en',
        AppLocale.spanish => 'es',
      };

  /// Toggle chip labels stay bilingual so users can switch back.
  String get label => switch (this) {
        AppLocale.english => 'English',
        AppLocale.spanish => 'Español',
      };

  static AppLocale fromCode(String? code) {
    if (code == 'es') return AppLocale.spanish;
    return AppLocale.english;
  }
}
