import 'package:flutter/material.dart';
import 'package:hvac_admin/core/controllers/translate_controller.dart';
import 'package:hvac_admin/design_system/design_system.dart';
import 'package:hvac_admin/features/shared/widgets/language_toggle.dart';
import 'package:provider/provider.dart';

/// Shows original text with on-demand EN↔ES translation (never mutates source).
class TranslatableTextBlock extends StatefulWidget {
  const TranslatableTextBlock({
    super.key,
    required this.text,
    required this.style,
    this.targetLocale = 'es',
    this.emptyLabel,
  });

  final String text;
  final TextStyle style;
  final String targetLocale;
  final String? emptyLabel;

  @override
  State<TranslatableTextBlock> createState() => _TranslatableTextBlockState();
}

class _TranslatableTextBlockState extends State<TranslatableTextBlock> {
  bool _showTranslation = false;

  @override
  void didUpdateWidget(covariant TranslatableTextBlock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _showTranslation = false;
    }
  }

  Future<void> _onTranslate(TranslateController controller) async {
    final key = TranslateController.cacheKey(text: widget.text, targetLocale: widget.targetLocale);
    if (controller.cached(key) != null) {
      setState(() => _showTranslation = true);
      return;
    }
    final result = await controller.translate(text: widget.text, targetLocale: widget.targetLocale);
    if (!mounted) return;
    if (result != null) setState(() => _showTranslation = true);
  }

  @override
  Widget build(BuildContext context) {
    final strings = adminStrings(context);
    final text = widget.text.trim();
    if (text.isEmpty) {
      final empty = widget.emptyLabel ?? strings.noNotesYet;
      if (empty.isEmpty) return const SizedBox.shrink();
      return Text(empty, style: AppTypography.bodySmall);
    }

    final controller = context.watch<TranslateController>();
    final key = TranslateController.cacheKey(text: text, targetLocale: widget.targetLocale);
    final cached = controller.cached(key);
    final loading = controller.isLoading(key);
    final error = controller.errorFor(key);
    final showing = _showTranslation && cached != null;

    return Column(
      key: const Key('translatable-text-block'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(text, style: widget.style),
        if (showing) ...[
          const SizedBox(height: AppSpacing.sm),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.primaryMuted,
              borderRadius: AppRadii.mdAll,
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Translation (${widget.targetLocale.toUpperCase()})',
                  style: AppTypography.labelSmall,
                ),
                const SizedBox(height: 4),
                Text(cached.translatedText, style: widget.style),
              ],
            ),
          ),
        ],
        if (error != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            error.contains('not configured') ? strings.translationUnavailable : error,
            style: AppTypography.labelSmall.copyWith(color: AppColors.danger),
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            key: showing ? const Key('show-original-button') : const Key('translate-button'),
            onPressed: loading
                ? null
                : () {
                    if (showing) {
                      setState(() => _showTranslation = false);
                      return;
                    }
                    _onTranslate(controller);
                  },
            icon: Icon(showing ? Icons.undo : Icons.translate, size: 18),
            label: Text(loading ? strings.translating : (showing ? strings.showOriginal : strings.translate)),
          ),
        ),
      ],
    );
  }
}
