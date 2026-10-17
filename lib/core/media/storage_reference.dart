import 'package:hvac_admin/core/media/stored_media_object.dart';

/// Parses `bucket/path/to/object` storage keys used in company settings and documents.
abstract final class StorageReference {
  StorageReference._();

  static const hvacBuckets = {
    'job_photos',
    'equipment_manuals',
    'documents',
    'signatures',
    'signed_documents',
  };

  static StoredMediaObject? parse(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    final slash = trimmed.indexOf('/');
    if (slash <= 0 || slash >= trimmed.length - 1) return null;
    final bucket = trimmed.substring(0, slash);
    if (!hvacBuckets.contains(bucket)) return null;
    return StoredMediaObject(bucket: bucket, path: trimmed.substring(slash + 1));
  }
}
