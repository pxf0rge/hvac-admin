import 'package:flutter_test/flutter_test.dart';
import 'package:hvac_admin/core/enums/admin_module.dart';
import 'package:hvac_admin/core/l10n/admin_strings.dart';
import 'package:hvac_admin/core/l10n/app_locale.dart';
import 'package:hvac_admin/core/l10n/locale_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('AdminStrings switches module labels for Spanish', () {
    const en = AdminStrings(AppLocale.english);
    const es = AdminStrings(AppLocale.spanish);
    expect(en.module(AdminModule.dispatch), 'Dispatch');
    expect(es.module(AdminModule.dispatch), 'Despacho');
    expect(en.signOut, 'Sign out');
    expect(es.signOut, 'Cerrar sesión');
    expect(es.documentsStayEnglish, contains('inglés'));
  });

  test('LocaleController persists admin locale separately', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final controller = LocaleController(prefs: prefs);
    await controller.load();
    expect(controller.locale, AppLocale.english);

    await controller.setLocale(AppLocale.spanish);
    expect(controller.locale, AppLocale.spanish);
    expect(prefs.getString(LocaleController.prefsKey), 'es');

    final again = LocaleController(prefs: prefs);
    await again.load();
    expect(again.locale, AppLocale.spanish);
    expect(LocaleController.prefsKey, 'hvac_admin.locale');
  });
}
