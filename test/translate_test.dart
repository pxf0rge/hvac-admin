import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hvac_admin/core/controllers/translate_controller.dart';
import 'package:hvac_admin/core/l10n/locale_controller.dart';
import 'package:hvac_admin/core/translate/translate_repository.dart';
import 'package:hvac_admin/features/shared/widgets/translatable_text_block.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpBlock(
    WidgetTester tester, {
    required TranslateController translate,
    String text = 'Replaced capacitor',
    String targetLocale = 'es',
  }) async {
    SharedPreferences.setMockInitialValues({});
    final locale = LocaleController(prefs: await SharedPreferences.getInstance());
    await locale.load();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<LocaleController>.value(value: locale),
          ChangeNotifierProvider<TranslateController>.value(value: translate),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: TranslatableTextBlock(
              text: text,
              style: const TextStyle(fontSize: 14),
              targetLocale: targetLocale,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('Translate toggle shows translation then original', (tester) async {
    final repo = MockTranslateRepository();
    final controller = TranslateController(repo);
    await pumpBlock(tester, translate: controller);

    expect(find.text('Replaced capacitor'), findsOneWidget);
    expect(find.byKey(const Key('translate-button')), findsOneWidget);

    await tester.tap(find.byKey(const Key('translate-button')));
    await tester.pumpAndSettle();

    expect(find.text('[ES] Replaced capacitor'), findsOneWidget);
    expect(find.byKey(const Key('show-original-button')), findsOneWidget);
    expect(repo.calls, hasLength(1));

    await tester.tap(find.byKey(const Key('show-original-button')));
    await tester.pumpAndSettle();

    expect(find.text('[ES] Replaced capacitor'), findsNothing);
    expect(find.byKey(const Key('translate-button')), findsOneWidget);
  });

  testWidgets('Missing provider shows clear error', (tester) async {
    final repo = MockTranslateRepository(
      failWith: const TranslateException('TRANSLATION_NOT_CONFIGURED', 'DeepL missing'),
    );
    final controller = TranslateController(repo);
    await pumpBlock(tester, translate: controller, text: 'Hola', targetLocale: 'en');

    await tester.tap(find.byKey(const Key('translate-button')));
    await tester.pumpAndSettle();

    expect(find.text('Translation is not configured yet.'), findsOneWidget);
    expect(find.textContaining('[EN]'), findsNothing);
  });
}
