import 'dart:typed_data';

import 'package:hvac_admin/core/media/stored_media_object.dart';

/// Authenticated storage access for private HVAC buckets.
abstract class AdminMediaStorage {
  static const defaultSignedUrlTtl = Duration(minutes: 15);

  Future<Uint8List?> downloadObject(StoredMediaObject object);

  Future<String?> signedUrlForObject(
    StoredMediaObject object, {
    Duration expiresIn = defaultSignedUrlTtl,
  });
}

class LocalAdminMediaStorage implements AdminMediaStorage {
  @override
  Future<Uint8List?> downloadObject(StoredMediaObject object) async => null;

  @override
  Future<String?> signedUrlForObject(
    StoredMediaObject object, {
    Duration expiresIn = AdminMediaStorage.defaultSignedUrlTtl,
  }) async =>
      null;
}
