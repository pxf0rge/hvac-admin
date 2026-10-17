import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hvac_admin/core/errors/failure_mapper.dart';
import 'package:hvac_admin/core/errors/hvac_failure.dart';
import 'package:hvac_admin/core/errors/storage_access_exception.dart';
import 'package:hvac_admin/core/media/storage_media_validator.dart';
import 'package:hvac_admin/core/media/storage_reference.dart';
import 'package:hvac_admin/core/security/auth_role_policy.dart';

void main() {
  group('StorageMediaValidator', () {
    test('accepts valid PNG signature bytes', () {
      final png = Uint8List.fromList([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00]);
      expect(() => StorageMediaValidator.validateSignature(png), returnsNormally);
    });

    test('rejects non-PDF bytes', () {
      expect(
        () => StorageMediaValidator.validatePdf(Uint8List.fromList([1, 2, 3, 4])),
        throwsA(isA<StorageMediaValidationException>()),
      );
    });

    test('limits match shared bucket config', () {
      expect(StorageMediaValidator.imageMaxBytes, 15728640);
      expect(StorageMediaValidator.signatureMaxBytes, 5242880);
      expect(StorageMediaValidator.pdfMaxBytes, 52428800);
    });
  });

  test('StorageAccessException maps to UnauthorizedFailure', () {
    final failure = FailureMapper.map(
      const StorageAccessException('denied', bucket: 'documents', path: 'company/logo.png'),
    );
    expect(failure, isA<UnauthorizedFailure>());
  });

  group('StorageReference', () {
    test('parses documents bucket paths', () {
      final object = StorageReference.parse('documents/company/logo.png');
      expect(object?.bucket, 'documents');
      expect(object?.path, 'company/logo.png');
    });

    test('rejects unknown buckets', () {
      expect(StorageReference.parse('public/logo.png'), isNull);
    });
  });

  group('AuthRolePolicy', () {
    test('flags privileged metadata keys', () {
      expect(AuthRolePolicy.isPrivilegedMetadataKey('role'), isTrue);
      expect(AuthRolePolicy.isPrivilegedMetadataKey('company_name'), isFalse);
    });
  });
}
