import 'package:flutter/material.dart';
import 'package:hvac_admin/core/models/office_job.dart';
import 'package:hvac_admin/core/utils/formatters.dart';
import 'package:hvac_admin/design_system/tokens/tokens.dart';

class JobStatusTimeline extends StatelessWidget {
  const JobStatusTimeline({super.key, required this.events});

  final List<JobStatusEvent> events;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return const Text('No status history yet.', style: AppTypography.bodySmall);
    }
    return Column(
      children: [
        for (var i = 0; i < events.length; i++)
          _TimelineRow(event: events[i], isLast: i == events.length - 1),
      ],
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.event, required this.isLast});

  final JobStatusEvent event;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 10,
              height: 10,
              margin: const EdgeInsets.only(top: 4),
              decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: AppColors.border,
              ),
          ],
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event.displayLabel, style: AppTypography.titleMedium),
                Text(formatDate(event.at.split('T').first), style: AppTypography.bodySmall),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
