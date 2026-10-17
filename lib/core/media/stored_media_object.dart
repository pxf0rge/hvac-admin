class StoredMediaObject {
  const StoredMediaObject({
    required this.bucket,
    required this.path,
  });

  final String bucket;
  final String path;

  String get objectKey => '$bucket/$path';
}
