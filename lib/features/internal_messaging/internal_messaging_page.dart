import 'package:flutter/material.dart';
import 'package:hvac_admin/core/controllers/internal_messaging_controller.dart';
import 'package:hvac_admin/core/controllers/technician_controller.dart';
import 'package:hvac_admin/core/models/internal_message.dart';
import 'package:hvac_admin/core/utils/formatters.dart';
import 'package:hvac_admin/design_system/design_system.dart';
import 'package:hvac_admin/features/shared/widgets/language_toggle.dart';
import 'package:provider/provider.dart';

class InternalMessagingPage extends StatefulWidget {
  const InternalMessagingPage({super.key});

  @override
  State<InternalMessagingPage> createState() => _InternalMessagingPageState();
}

class _InternalMessagingPageState extends State<InternalMessagingPage> {
  final _compose = TextEditingController();
  String? _selectedThreadId;
  String? _newTechnicianId;
  bool _starting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final technicians = context.read<TechnicianController>();
      final inbox = context.read<InternalMessagingController>();
      await technicians.load();
      if (!mounted) return;
      await inbox.loadInbox(force: true);
    });
  }

  @override
  void dispose() {
    _compose.dispose();
    super.dispose();
  }

  Future<void> _openThread(String threadId) async {
    setState(() => _selectedThreadId = threadId);
    await context.read<InternalMessagingController>().openThread(threadId);
  }

  Future<void> _startThread() async {
    final techId = _newTechnicianId;
    if (techId == null) return;
    setState(() => _starting = true);
    try {
      final thread = await context.read<InternalMessagingController>().startThread(
            technicianId: techId,
          );
      if (mounted) setState(() => _selectedThreadId = thread.id);
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  Future<void> _send() async {
    final threadId = _selectedThreadId;
    final body = _compose.text.trim();
    if (threadId == null || body.isEmpty) return;
    await context.read<InternalMessagingController>().send(threadId: threadId, body: body);
    _compose.clear();
  }

  @override
  Widget build(BuildContext context) {
    final inbox = context.watch<InternalMessagingController>();
    final technicians = context.watch<TechnicianController>().technicians;
    final strings = adminStrings(context);
    final selected = _selectedThreadId == null ? null : inbox.threadById(_selectedThreadId!);
    final messages = _selectedThreadId == null ? const <InternalMessage>[] : inbox.messagesFor(_selectedThreadId!);
    final wide = MediaQuery.sizeOf(context).width >= AppBreakpoints.mobile;

    final threadList = SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(title: strings.moduleLabelTeamMessages),
          if (inbox.error != null)
            Text(inbox.error!, style: AppTypography.bodySmall.copyWith(color: AppColors.danger)),
          InputDecorator(
            decoration: InputDecoration(labelText: strings.newMessageToTechnician),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                key: const Key('internal-new-technician'),
                value: technicians.any((t) => t.id == _newTechnicianId) ? _newTechnicianId : null,
                isExpanded: true,
                hint: Text(strings.selectTechnician),
                items: [
                  for (final tech in technicians)
                    DropdownMenuItem(
                      value: tech.id,
                      child: Text(tech.displayName, overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: (value) => setState(() => _newTechnicianId = value),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppPrimaryButton(
            key: const Key('internal-start-thread'),
            label: _starting ? strings.loading : strings.startConversation,
            onPressed: _newTechnicianId == null || _starting ? null : _startThread,
          ),
          const SizedBox(height: AppSpacing.md),
          if (inbox.isLoading && inbox.threads.isEmpty)
            const Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (inbox.threads.isEmpty)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(strings.noTeamThreads, style: AppTypography.bodySmall),
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount: inbox.threads.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final thread = inbox.threads[index];
                  final selectedRow = thread.id == _selectedThreadId;
                  return ListTile(
                    key: Key('internal-thread-${thread.id}'),
                    selected: selectedRow,
                    title: Text(thread.title, style: AppTypography.titleMedium),
                    subtitle: Text(
                      thread.lastMessagePreview.isEmpty ? '—' : thread.lastMessagePreview,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall,
                    ),
                    trailing: thread.unreadCount > 0
                        ? StatusChip(
                            label: '${thread.unreadCount}',
                            background: AppColors.primaryMuted,
                            foreground: AppColors.primary,
                          )
                        : Text(
                            thread.lastMessageAt.isEmpty ? '' : formatDate(thread.lastMessageAt.split('T').first),
                            style: AppTypography.labelSmall,
                          ),
                    onTap: () => _openThread(thread.id),
                  );
                },
              ),
            ),
        ],
      ),
    );

    final conversation = SurfaceCard(
      child: selected == null
          ? Center(child: Text(strings.selectThreadHint, style: AppTypography.bodyMedium))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(selected.title, style: AppTypography.titleLarge),
                const SizedBox(height: AppSpacing.sm),
                Expanded(
                  child: ListView.builder(
                    key: Key('internal-messages-${selected.id}'),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final align = message.fromOffice ? Alignment.centerRight : Alignment.centerLeft;
                      final bg = message.fromOffice ? AppColors.primaryMuted : AppColors.background;
                      return Align(
                        alignment: align,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          constraints: const BoxConstraints(maxWidth: 420),
                          decoration: BoxDecoration(
                            color: bg,
                            borderRadius: AppRadii.mdAll,
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                message.senderName.isEmpty
                                    ? (message.fromOffice ? strings.office : strings.technicianLabel)
                                    : message.senderName,
                                style: AppTypography.labelSmall,
                              ),
                              Text(message.body, style: AppTypography.bodyMedium),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        key: const Key('internal-compose'),
                        controller: _compose,
                        label: strings.message,
                        hint: strings.typeMessage,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    AppPrimaryButton(
                      key: const Key('internal-send'),
                      label: strings.send,
                      onPressed: _send,
                    ),
                  ],
                ),
              ],
            ),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.xl),
      child: wide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(width: 360, child: threadList),
                const SizedBox(width: AppSpacing.lg),
                Expanded(child: conversation),
              ],
            )
          : Column(
              children: [
                SizedBox(height: 280, child: threadList),
                const SizedBox(height: AppSpacing.md),
                Expanded(child: conversation),
              ],
            ),
    );
  }
}
