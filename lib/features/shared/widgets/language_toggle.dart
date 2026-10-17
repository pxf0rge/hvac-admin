import 'package:flutter/material.dart';
import 'package:hvac_admin/core/l10n/admin_strings.dart';
import 'package:hvac_admin/core/l10n/app_locale.dart';
import 'package:hvac_admin/core/l10n/locale_controller.dart';
import 'package:hvac_admin/design_system/design_system.dart';
import 'package:provider/provider.dart';

/// EN / ES switch for the office app (independent of technician field locale).
class LanguageToggle extends StatelessWidget {
  const LanguageToggle({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<LocaleController>();
    final selected = controller.locale;

    final chips = SegmentedButton<AppLocale>(
      key: const Key('admin-language-toggle'),
      segments: [
        for (final locale in AppLocale.values)
          ButtonSegment(
            value: locale,
            label: Text(locale.label),
            icon: Icon(locale == AppLocale.spanish ? Icons.language : Icons.translate, size: 16),
          ),
      ],
      selected: {selected},
      onSelectionChanged: (value) => controller.setLocale(value.first),
    );

    if (compact) return chips;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(controller.strings.languageSection, style: AppTypography.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        Text(controller.strings.languageHint, style: AppTypography.bodySmall),
        const SizedBox(height: AppSpacing.md),
        chips,
        const SizedBox(height: AppSpacing.sm),
        Text(controller.strings.documentsStayEnglish, style: AppTypography.labelSmall),
      ],
    );
  }
}

AdminStrings adminStrings(BuildContext context) => context.watch<LocaleController>().strings;

AdminStrings adminStringsRead(BuildContext context) => context.read<LocaleController>().strings;
