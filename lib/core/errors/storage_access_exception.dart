/// Thrown when private storage access is denied (RLS / IDOR).
class StorageAccessException implements Exception {
  const StorageAccessException(this.message, {this.bucket, this.path});

  final String message;
  final String? bucket;
  final String? path;

  @override
  String toString() => message;
}
