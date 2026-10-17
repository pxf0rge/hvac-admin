import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hvac_admin/core/enums/domain_enums.dart';
import 'package:hvac_admin/core/errors/failure_mapper.dart';
import 'package:hvac_admin/core/errors/hvac_failure.dart';
import 'package:hvac_admin/core/models/office_billing.dart';
import 'package:hvac_admin/core/validation/billing_validators.dart';
import 'package:hvac_admin/core/validation/field_validators.dart';
import 'package:hvac_admin/core/validation/inventory_validators.dart';
import 'package:hvac_admin/core/validation/scheduling_validators.dart';
import 'package:postgrest/postgrest.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('FieldValidators', () {
    test('phone rejects short numbers before submit', () {
      expect(FieldValidators.phone('123'), isNotNull);
      expect(FieldValidators.phone('(217) 555-0100'), isNull);
    });

    test('positiveDecimal validates quantity text', () {
      expect(FieldValidators.positiveDecimal('0', label: 'Quantity'), isNotNull);
      expect(FieldValidators.positiveDecimal('2.5', label: 'Quantity'), isNull);
    });
  });

  group('BillingValidators', () {
    test('requires at least one line item', () {
      expect(
        () => BillingValidators.validateEstimate(
          const OfficeEstimate(
            id: '1',
            number: 'EST-1',
            status: EstimateStatus.draft,
            date: '2026-08-30',
            propertyId: 'p1',
            jobId: 'j1',
            notes: '',
            items: [],
          ),
        ),
        throwsA(isA<BillingValidationException>()),
      );
    });
  });

  group('InventoryValidators', () {
    test('positiveQuantity rejects zero', () {
      expect(InventoryValidators.positiveQuantity('0', label: 'Quantity'), isNotNull);
      expect(InventoryValidators.positiveQuantity('3', label: 'Quantity'), isNull);
    });
  });

  group('SchedulingValidators', () {
    test('endAfterStart rejects inverted window', () {
      expect(SchedulingValidators.endAfterStart('09:00', '08:00'), isNotNull);
      expect(SchedulingValidators.endAfterStart('09:00', '11:00'), isNull);
    });
  });

  group('FailureMapper', () {
    test('maps network errors to retryable NetworkFailure', () {
      final failure = FailureMapper.map(const SocketException('Failed host lookup'));
      expect(failure, isA<NetworkFailure>());
      expect(failure.isRetryable, isTrue);
    });

    test('maps billing validation to ValidationFailure', () {
      final failure = FailureMapper.map(
        const BillingValidationException('Invoice total must be greater than zero.'),
      );
      expect(failure, isA<ValidationFailure>());
    });

    test('maps RLS denial to permission message', () {
      final failure = FailureMapper.map(
        const PostgrestException(
          message: 'permission denied for table invoices',
          code: '42501',
        ),
      );
      expect(failure, isA<UnauthorizedFailure>());
      expect(failure.message, contains('permission'));
    });

    test('maps auth errors to UnauthorizedFailure', () {
      final failure = FailureMapper.map(const AuthException('JWT expired'));
      expect(failure, isA<UnauthorizedFailure>());
    });
  });
}
