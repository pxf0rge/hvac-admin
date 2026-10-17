import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hvac_admin/design_system/design_system.dart';
import 'package:hvac_admin/features/settings/integration_help_guide.dart';

Future<void> showIntegrationHelpDialog(
  BuildContext context, {
  required IntegrationHelpTopic topic,
}) {
  final guide = IntegrationHelpGuide.forTopic(topic);
  return showDialog<void>(
    context: context,
    builder: (ctx) => IntegrationHelpDialog(guide: guide, topic: topic),
  );
}

class IntegrationHelpDialog extends StatelessWidget {
  const IntegrationHelpDialog({
    super.key,
    required this.guide,
    required this.topic,
  });

  final IntegrationHelpGuide guide;
  final IntegrationHelpTopic topic;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      titlePadding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xl, AppSpacing.md, AppSpacing.sm),
      contentPadding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.md),
      actionsPadding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
      title: Row(
        children: [
          const Icon(Icons.help_outline, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(guide.title, style: AppTypography.titleMedium),
          ),
        ],
      ),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          key: Key('integration-help-${topic.name}'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(guide.summary, style: AppTypography.bodyMedium),
              if (guide.officialUrl != null) ...[
                const SizedBox(height: AppSpacing.md),
                _CopyableLink(url: guide.officialUrl!),
              ],
              const SizedBox(height: AppSpacing.lg),
              Text('Step by step', style: AppTypography.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              ..._buildSteps(guide.steps),
              if (guide.tips.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                Text('Tips', style: AppTypography.titleMedium),
                const SizedBox(height: AppSpacing.sm),
                for (final tip in guide.tips) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('•  ', style: AppTypography.bodySmall),
                      Expanded(child: Text(tip, style: AppTypography.bodySmall)),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                ],
              ],
            ],
          ),
        ),
      ),
      actions: [
        AppPrimaryButton(
          key: const Key('integration-help-close'),
          label: 'Got it',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  List<Widget> _buildSteps(List<String> steps) {
    final widgets = <Widget>[];
    var stepNumber = 0;
    for (var i = 0; i < steps.length; i++) {
      final text = steps[i];
      final isHeader = text.startsWith('Option A') || text.startsWith('Option B');
      if (!isHeader) stepNumber += 1;
      widgets.add(_StepRow(index: stepNumber, text: text, isSectionHeader: isHeader));
      if (i != steps.length - 1) {
        widgets.add(const SizedBox(height: AppSpacing.sm));
      }
    }
    return widgets;
  }
}

class _CopyableLink extends StatelessWidget {
  const _CopyableLink({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceHover,
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.md),
        onTap: () async {
          await Clipboard.setData(ClipboardData(text: url));
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Link copied — paste it in your browser')),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          child: Row(
            children: [
              const Icon(Icons.link, size: 18, color: AppColors.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  url,
                  style: AppTypography.bodySmall.copyWith(color: AppColors.primary),
                ),
              ),
              const Icon(Icons.copy, size: 16, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.index,
    required this.text,
    this.isSectionHeader = false,
  });

  final int index;
  final String text;
  final bool isSectionHeader;

  @override
  Widget build(BuildContext context) {
    if (isSectionHeader) {
      return Padding(
        padding: const EdgeInsets.only(top: AppSpacing.sm),
        child: Text(text, style: AppTypography.labelMedium.copyWith(color: AppColors.primary)),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primaryMuted,
            borderRadius: BorderRadius.circular(AppRadii.sm),
          ),
          child: Text(
            '$index',
            style: AppTypography.labelMedium.copyWith(color: AppColors.primary),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(text, style: AppTypography.bodySmall)),
      ],
    );
  }
}
