import 'dart:typed_data';

/// Thrown when storage upload validation fails (MIME/size).
class StorageMediaValidationException implements Exception {
  const StorageMediaValidationException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Upload validators aligned with `storage.buckets` limits (Phase 32).
abstract final class StorageMediaValidator {
  static const signatureMaxBytes = 5242880;
  static const pdfMaxBytes = 52428800;
  static const imageMaxBytes = 15728640;

  static const signatureMimeTypes = {'image/png', 'image/jpeg'};
  static const pdfMimeTypes = {'application/pdf'};
  static const imageMimeTypes = {'image/jpeg', 'image/png', 'image/webp', 'image/heic'};

  static void validateSignature(Uint8List bytes) {
    if (bytes.isEmpty) {
      throw const StorageMediaValidationException('Signature image is empty.');
    }
    if (bytes.length > signatureMaxBytes) {
      throw const StorageMediaValidationException('Signature must be 5 MB or smaller.');
    }
    final mime = _detectImageMime(bytes);
    if (!signatureMimeTypes.contains(mime)) {
      throw const StorageMediaValidationException('Signature must be a PNG or JPEG image.');
    }
  }

  static void validatePdf(Uint8List bytes) {
    if (bytes.isEmpty) {
      throw const StorageMediaValidationException('PDF is empty.');
    }
    if (bytes.length > pdfMaxBytes) {
      throw const StorageMediaValidationException('PDF must be 50 MB or smaller.');
    }
    if (bytes.length < 4 ||
        bytes[0] != 0x25 ||
        bytes[1] != 0x50 ||
        bytes[2] != 0x44 ||
        bytes[3] != 0x46) {
      throw const StorageMediaValidationException('File is not a valid PDF.');
    }
  }

  static void validateImage(Uint8List bytes, {String? sourcePath}) {
    if (bytes.isEmpty) {
      throw const StorageMediaValidationException('Image is empty.');
    }
    if (bytes.length > imageMaxBytes) {
      throw const StorageMediaValidationException('Image must be 15 MB or smaller.');
    }
    final mime = _detectImageMime(bytes, sourcePath: sourcePath);
    if (!imageMimeTypes.contains(mime)) {
      throw const StorageMediaValidationException('Unsupported image type.');
    }
  }

  static String _detectImageMime(Uint8List bytes, {String? sourcePath}) {
    if (bytes.length >= 3 && bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
      return 'image/jpeg';
    }
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return 'image/png';
    }
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return 'image/webp';
    }
    final lower = sourcePath?.toLowerCase();
    if (lower != null) {
      if (lower.endsWith('.heic') || lower.endsWith('.heif')) return 'image/heic';
      if (lower.endsWith('.png')) return 'image/png';
      if (lower.endsWith('.webp')) return 'image/webp';
    }
    return 'application/octet-stream';
  }
}
