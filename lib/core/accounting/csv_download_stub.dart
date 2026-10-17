bool downloadTextFileImpl({
  required String filename,
  required String content,
  String mimeType = 'text/csv;charset=utf-8',
}) {
  // Desktop/mobile: caller should fall back to clipboard / share.
  return false;
}
