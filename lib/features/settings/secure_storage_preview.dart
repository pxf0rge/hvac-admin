import 'package:flutter/material.dart';
import 'package:hvac_admin/core/media/secure_media_access.dart';
import 'package:hvac_admin/core/media/storage_reference.dart';
import 'package:hvac_admin/design_system/design_system.dart';

/// Renders a private storage object via a short-lived signed URL.
class SecureStoragePreview extends StatefulWidget {
  const SecureStoragePreview({
    super.key,
    required this.storagePath,
    required this.mediaAccess,
    this.height = 96,
  });

  final String storagePath;
  final SecureMediaAccess mediaAccess;
  final double height;

  @override
  State<SecureStoragePreview> createState() => _SecureStoragePreviewState();
}

class _SecureStoragePreviewState extends State<SecureStoragePreview> {
  String? _signedUrl;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(covariant SecureStoragePreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.storagePath != widget.storagePath) {
      _resolve();
    }
  }

  Future<void> _resolve() async {
    final object = StorageReference.parse(widget.storagePath);
    if (object == null) {
      setState(() {
        _signedUrl = null;
        _error = null;
        _loading = false;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _signedUrl = null;
    });
    final url = await widget.mediaAccess.signedUrl(object, event: 'settings.logo_preview');
    if (!mounted) return;
    setState(() {
      _loading = false;
      _signedUrl = url;
      if (url == null) _error = 'Logo preview unavailable (check storage permissions).';
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.storagePath.trim().isEmpty) return const SizedBox.shrink();
    final object = StorageReference.parse(widget.storagePath);
    if (object == null) {
      return Text(
        'Storage path must be bucket/path (e.g. documents/company/logo.png).',
        style: AppTypography.bodySmall.copyWith(color: AppColors.warning),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Private bucket preview (signed URL, 15 min TTL)', style: AppTypography.labelMedium),
        const SizedBox(height: AppSpacing.sm),
        if (_loading)
          SizedBox(
            height: widget.height,
            child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          )
        else if (_signedUrl != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              _signedUrl!,
              height: widget.height,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => Text('Could not load logo preview.', style: AppTypography.bodySmall),
            ),
          )
        else if (_error != null)
          Text(_error!, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
      ],
    );
  }
}
