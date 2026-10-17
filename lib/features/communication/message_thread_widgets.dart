import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hvac_admin/core/controllers/communication_controller.dart';
import 'package:hvac_admin/core/enums/domain_enums.dart';
import 'package:hvac_admin/core/models/message_history_filter.dart';
import 'package:hvac_admin/core/models/message_thread_summary.dart';
import 'package:hvac_admin/core/models/office_message.dart';
import 'package:hvac_admin/core/utils/formatters.dart';
import 'package:hvac_admin/design_system/design_system.dart';
import 'package:hvac_admin/features/communication/communication_page.dart';
import 'package:hvac_admin/features/shared/widgets/paged_search_list.dart';
import 'package:provider/provider.dart';

enum MessageDateRangePreset { all, last7Days, last30Days }

extension MessageDateRangePresetX on MessageDateRangePreset {
  MessageHistoryFilter? toFilter(DateTime now) => switch (this) {
        MessageDateRangePreset.all => null,
        MessageDateRangePreset.last7Days => MessageHistoryFilter(from: now.subtract(const Duration(days: 7))),
        MessageDateRangePreset.last30Days => MessageHistoryFilter(from: now.subtract(const Duration(days: 30))),
      };

  String get label => switch (this) {
        MessageDateRangePreset.all => 'All time',
        MessageDateRangePreset.last7Days => 'Last 7 days',
        MessageDateRangePreset.last30Days => 'Last 30 days',
      };
}

class MessageHistoryFiltersBar extends StatelessWidget {
  const MessageHistoryFiltersBar({
    super.key,
    required this.channel,
    required this.datePreset,
    required this.onChannel,
    required this.onDatePreset,
  });

  final CommunicationChannel? channel;
  final MessageDateRangePreset datePreset;
  final ValueChanged<CommunicationChannel?> onChannel;
  final ValueChanged<MessageDateRangePreset> onDatePreset;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        FilterChip(
          label: const Text('All channels'),
          selected: channel == null,
          onSelected: (_) => onChannel(null),
        ),
        for (final item in [CommunicationChannel.sms, CommunicationChannel.email])
          FilterChip(
            label: Text(item.label),
            selected: channel == item,
            onSelected: (_) => onChannel(item),
          ),
        for (final preset in MessageDateRangePreset.values)
          FilterChip(
            label: Text(preset.label),
            selected: datePreset == preset,
            onSelected: (_) => onDatePreset(preset),
          ),
      ],
    );
  }
}

class MessageBubble extends StatelessWidget {
  const MessageBubble({super.key, required this.message, this.compact = false});

  final OfficeMessage message;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final outbound = message.direction == MessageDirection.outbound;
    final colors = switch (message.channel) {
      CommunicationChannel.sms => (AppColors.primaryMuted, AppColors.primary),
      CommunicationChannel.email => (AppColors.successMuted, AppColors.success),
      CommunicationChannel.system => (AppColors.surfaceHover, AppColors.textMuted),
    };
    final failed = message.deliveryStatus == 'failed';
    return Align(
      alignment: outbound ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: compact ? 420 : 520),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: outbound ? AppColors.primaryMuted : AppColors.surfaceHover,
            borderRadius: AppRadii.lgAll,
            border: Border.all(color: failed ? AppColors.danger : AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  StatusChip(
                    label: message.direction.label,
                    background: outbound ? AppColors.primaryMuted : AppColors.surfaceHover,
                    foreground: outbound ? AppColors.primary : AppColors.textSecondary,
                  ),
                  StatusChip(label: message.channel.label, background: colors.$1, foreground: colors.$2),
                  if (!compact) StatusChip(label: message.entityType.label),
                ],
              ),
              if (!compact) ...[
                const SizedBox(height: 8),
                Text(message.entityLabel, style: AppTypography.titleMedium),
              ],
              if (message.subject.isNotEmpty) Text(message.subject, style: AppTypography.bodyMedium),
              Text(message.body, style: AppTypography.bodySmall),
              const SizedBox(height: 4),
              Text(
                [
                  formatDate(message.at),
                  if (message.templateKind != null) message.templateKind!,
                  if (message.localeCode != null) message.localeCode!.toUpperCase(),
                  message.deliveryStatus,
                ].join('  ·  '),
                style: AppTypography.labelSmall.copyWith(color: failed ? AppColors.danger : null),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MessageThreadPanel extends StatefulWidget {
  const MessageThreadPanel({
    super.key,
    required this.entities,
    this.listKey,
    this.showFilters = true,
    this.showReply = true,
    this.replyEntityType,
    this.replyEntityId,
    this.compact = true,
    this.height = 360,
  });

  final List<MessageEntityRef> entities;
  final Key? listKey;
  final bool showFilters;
  final bool showReply;
  final CommunicationEntityType? replyEntityType;
  final String? replyEntityId;
  final bool compact;
  final double height;

  @override
  State<MessageThreadPanel> createState() => _MessageThreadPanelState();
}

class _MessageThreadPanelState extends State<MessageThreadPanel> {
  CommunicationChannel? _channel;
  MessageDateRangePreset _datePreset = MessageDateRangePreset.all;
  int _refreshToken = 0;

  MessageHistoryFilter? get _filter {
    final base = _datePreset.toFilter(DateTime.now());
    if (_channel == null && base == null) return null;
    return (base ?? const MessageHistoryFilter()).copyWith(
      channel: _channel,
      clearChannel: _channel == null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final inbox = context.watch<CommunicationController>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.showFilters) ...[
          MessageHistoryFiltersBar(
            channel: _channel,
            datePreset: _datePreset,
            onChannel: (value) => setState(() {
              _channel = value;
              _refreshToken++;
            }),
            onDatePreset: (value) => setState(() {
              _datePreset = value;
              _refreshToken++;
            }),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (widget.showReply && widget.replyEntityType != null && widget.replyEntityId != null)
          Align(
            alignment: Alignment.centerRight,
            child: AppSecondaryButton(
              key: Key('message-reply-${widget.replyEntityId}'),
              label: 'Reply',
              icon: Icons.reply_outlined,
              onPressed: () => context.go(
                communicationPath(
                  entityType: widget.replyEntityType!,
                  entityId: widget.replyEntityId!,
                ),
              ),
            ),
          ),
        if (widget.showReply && widget.replyEntityType != null && widget.replyEntityId != null)
          const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: widget.height,
          child: SurfaceCard(
            padding: const EdgeInsets.all(12),
            child: PagedSearchList<OfficeMessage>(
              refreshToken: _refreshToken + inbox.refreshToken,
              listKey: widget.listKey ?? const Key('message-thread'),
              searchHint: 'Search name, phone, or message',
              emptyTitle: 'No messages yet',
              emptyMessage: 'Outbound sends and inbound replies appear here.',
              fetchPage: (offset, query) => inbox.fetchMessagesPage(
                offset: offset,
                search: query,
                entities: widget.entities,
                filter: _filter,
              ),
              itemBuilder: (context, message) => MessageBubble(message: message, compact: widget.compact),
            ),
          ),
        ),
      ],
    );
  }
}

class RecentMessageThreads extends StatelessWidget {
  const RecentMessageThreads({
    super.key,
    required this.threads,
    required this.onOpenThread,
    this.compact = false,
  });

  final List<MessageThreadSummary> threads;
  final void Function(MessageThreadSummary thread) onOpenThread;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (threads.isEmpty) return const SizedBox.shrink();
    if (compact) {
      return SizedBox(
        height: 136,
        child: ListView.separated(
          key: const Key('recent-message-threads'),
          scrollDirection: Axis.horizontal,
          itemCount: threads.length,
          separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
          itemBuilder: (context, index) {
            final thread = threads[index];
            return SizedBox(
              width: 260,
              child: _ThreadTile(thread: thread, onOpenThread: onOpenThread, compact: true),
            );
          },
        ),
      );
    }
    return SurfaceCard(
      key: const Key('recent-message-threads'),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeader(title: 'Recent threads'),
          const SizedBox(height: AppSpacing.sm),
          for (final thread in threads) ...[
            _ThreadTile(thread: thread, onOpenThread: onOpenThread),
            const Divider(height: 1),
          ],
        ],
      ),
    );
  }
}

class _ThreadTile extends StatelessWidget {
  const _ThreadTile({
    required this.thread,
    required this.onOpenThread,
    this.compact = false,
  });

  final MessageThreadSummary thread;
  final void Function(MessageThreadSummary thread) onOpenThread;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return InkWell(
        key: Key('thread-${thread.entityType.name}-${thread.entityId}'),
        onTap: () => onOpenThread(thread),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfaceHover,
            borderRadius: AppRadii.mdAll,
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(thread.entityLabel, style: AppTypography.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Text(
                '${thread.latest.direction.label} · ${thread.preview}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodySmall,
              ),
              const SizedBox(height: 6),
              Text(
                '${formatDate(thread.latest.at)} · ${thread.messageCount} msgs',
                style: AppTypography.labelSmall,
              ),
            ],
          ),
        ),
      );
    }
    return Material(
      color: Colors.transparent,
      child: ListTile(
        key: Key('thread-${thread.entityType.name}-${thread.entityId}'),
        contentPadding: EdgeInsets.zero,
        title: Text(thread.entityLabel, style: AppTypography.titleMedium),
        subtitle: Text(
          '${thread.latest.direction.label} · ${thread.preview}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.bodySmall,
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(formatDate(thread.latest.at), style: AppTypography.labelSmall),
            Text('${thread.messageCount} msgs', style: AppTypography.labelSmall),
          ],
        ),
        onTap: () => onOpenThread(thread),
      ),
    );
  }
}
