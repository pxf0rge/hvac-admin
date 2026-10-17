import 'csv_download_stub.dart' if (dart.library.html) 'csv_download_web.dart' as impl;

/// Triggers a browser download (web) or returns false when unavailable.
bool downloadTextFile({
  required String filename,
  required String content,
  String mimeType = 'text/csv;charset=utf-8',
}) {
  return impl.downloadTextFileImpl(
    filename: filename,
    content: content,
    mimeType: mimeType,
  );
}
