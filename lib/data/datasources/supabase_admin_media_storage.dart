import 'dart:typed_data';

import 'package:hvac_admin/core/media/admin_media_storage.dart';
import 'package:hvac_admin/core/media/stored_media_object.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Private-bucket downloads and short-lived signed URLs (RLS-enforced).
class SupabaseAdminMediaStorage implements AdminMediaStorage {
  SupabaseAdminMediaStorage(this._client);

  final SupabaseClient _client;

  @override
  Future<Uint8List?> downloadObject(StoredMediaObject object) async {
    return _client.storage.from(object.bucket).download(object.path);
  }

  @override
  Future<String?> signedUrlForObject(
    StoredMediaObject object, {
    Duration expiresIn = AdminMediaStorage.defaultSignedUrlTtl,
  }) async {
    return _client.storage.from(object.bucket).createSignedUrl(
          object.path,
          expiresIn.inSeconds,
        );
  }
}
