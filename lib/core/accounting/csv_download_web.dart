// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

bool downloadTextFileImpl({
  required String filename,
  required String content,
  String mimeType = 'text/csv;charset=utf-8',
}) {
  final bytes = html.Blob([content], mimeType);
  final url = html.Url.createObjectUrlFromBlob(bytes);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..style.display = 'none';
  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  html.Url.revokeObjectUrl(url);
  return true;
}
