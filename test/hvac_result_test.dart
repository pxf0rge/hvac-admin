import 'package:flutter_test/flutter_test.dart';
import 'package:hvac_admin/core/result/hvac_result.dart';
import 'package:hvac_admin/core/errors/hvac_failure.dart';

void main() {
  test('HvacResult success and failure', () {
    final ok = hvacSuccess(42);
    expect(ok.isSuccess, isTrue);
    expect(ok.valueOrNull, 42);

    const fail = HvacError<int>(ValidationFailure('bad input'));
    expect(fail.isFailure, isTrue);
    expect(fail.failureOrNull, isA<ValidationFailure>());
    expect(
      ok.when(success: (v) => 'ok:$v', onFailure: (_) => 'fail'),
      'ok:42',
    );
  });
}
