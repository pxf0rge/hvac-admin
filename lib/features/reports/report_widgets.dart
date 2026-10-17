import 'package:flutter/material.dart';
import 'package:hvac_admin/core/models/office_reports.dart';
import 'package:hvac_admin/design_system/design_system.dart';
import 'package:hvac_admin/features/shared/widgets/language_toggle.dart';

class ReportBarChart extends StatelessWidget {
  const ReportBarChart({super.key, required this.bars, this.emptyLabel});

  final List<JobVolumeBar> bars;

  /// Localized empty-state label (falls back to English).
  final String? emptyLabel;

  @override
  Widget build(BuildContext context) {
    if (bars.isEmpty) {
      return Text(emptyLabel ?? 'No jobs to chart.', style: AppTypography.bodySmall);
    }
    final max = bars.fold<int>(0, (current, bar) => bar.count > current ? bar.count : current);
    return Column(
      children: [
        for (final bar in bars)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              children: [
                SizedBox(
                  width: 168,
                  child: Text(bar.label, style: AppTypography.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final width = max == 0 ? 0.0 : constraints.maxWidth * (bar.count / max);
                      return SizedBox(
                        height: 10,
                        child: Stack(
                          children: [
                            Container(
                              height: 10,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceHover,
                                borderRadius: AppRadii.smAll,
                              ),
                            ),
                            Container(
                              width: width,
                              height: 10,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: AppRadii.smAll,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                SizedBox(
                  width: 24,
                  child: Text('${bar.count}', style: AppTypography.labelMedium, textAlign: TextAlign.end),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class TechnicianSummaryList extends StatelessWidget {
  const TechnicianSummaryList({super.key, required this.rows, this.emptyLabel});

  final List<TechnicianReportRow> rows;

  /// Localized empty-state label (falls back to English).
  final String? emptyLabel;

  @override
  Widget build(BuildContext context) {
    final strings = adminStrings(context);
    if (rows.isEmpty) {
      return Text(emptyLabel ?? 'No technician assignments yet.', style: AppTypography.bodySmall);
    }
    return Column(
      children: [
        for (final row in rows)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(row.name, style: AppTypography.bodyMedium),
                      if (row.avgMinutesOnSite != null || row.onTimePercent != null)
                        Text(
                          strings.technicianSummaryMeta(
                            '${row.avgMinutesOnSite ?? 0}m',
                            '${row.onTimePercent ?? 0}',
                          ),
                          style: AppTypography.labelMedium,
                        ),
                    ],
                  ),
                ),
                Text(
                  strings.technicianSummaryTotals(row.completed, row.total),
                  style: AppTypography.labelMedium,
                ),
              ],
            ),
          ),
      ],
    );
  }
}
