import 'package:flutter_test/flutter_test.dart';
import 'package:hvac_admin/core/config/app_environment.dart';
import 'package:hvac_admin/core/config/demo_credentials.dart';

void main() {
  test('demo login hints enabled only in development', () {
    expect(AppEnvironment.isDevelopment, isTrue);
    expect(DemoCredentials.showLoginHints, isTrue);
    expect(DemoCredentials.loginHint, contains('diana@hvacpro.com'));
    expect(DemoCredentials.loginHint, isNot(contains('marcus@hvacpro.com')));
  });
}
