import 'dart:typed_data';

import 'package:hvac_admin/core/errors/storage_access_exception.dart';
import 'package:hvac_admin/core/logging/hvac_log.dart';
import 'package:hvac_admin/core/media/admin_media_storage.dart';
import 'package:hvac_admin/core/media/stored_media_object.dart';

/// Authenticated download + short-lived signed URLs for private buckets.
class SecureMediaAccess {
  SecureMediaAccess(this._storage);

  final AdminMediaStorage _storage;

  static const defaultSignedUrlTtl = AdminMediaStorage.defaultSignedUrlTtl;

  Future<Uint8List?> download(StoredMediaObject object, {String event = 'media.download'}) async {
    try {
      return await _storage.downloadObject(object);
    } catch (error) {
      HvacLog.warn('$event.denied', fields: {
        'bucket': object.bucket,
        'path': object.path,
      }, error: error);
      throw StorageAccessException(
        'You do not have access to this file.',
        bucket: object.bucket,
        path: object.path,
      );
    }
  }

  Future<String?> signedUrl(
    StoredMediaObject object, {
    Duration expiresIn = defaultSignedUrlTtl,
    String event = 'media.signed_url',
  }) async {
    try {
      return await _storage.signedUrlForObject(object, expiresIn: expiresIn);
    } catch (error) {
      HvacLog.warn('$event.denied', fields: {
        'bucket': object.bucket,
        'path': object.path,
      }, error: error);
      return null;
    }
  }

  /// Tries authenticated download first, then a short-lived signed URL.
  Future<({Uint8List? bytes, String? signedUrl})> resolve(
    StoredMediaObject object, {
    String event = 'media.resolve',
  }) async {
    try {
      final bytes = await _storage.downloadObject(object);
      if (bytes != null && bytes.isNotEmpty) {
        return (bytes: bytes, signedUrl: null);
      }
    } catch (error) {
      HvacLog.warn('$event.download_denied', fields: {
        'bucket': object.bucket,
        'path': object.path,
      }, error: error);
    }

    final url = await signedUrl(object, event: event);
    return (bytes: null, signedUrl: url);
  }
}
