import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hvac_admin/core/controllers/communication_controller.dart';
import 'package:hvac_admin/core/controllers/customer_controller.dart';
import 'package:hvac_admin/core/controllers/job_controller.dart';
import 'package:hvac_admin/core/enums/domain_enums.dart';
import 'package:hvac_admin/core/messaging/message_templates.dart';
import 'package:hvac_admin/core/messaging/message_variables.dart';
import 'package:hvac_admin/core/messaging/messaging_send_exception.dart';
import 'package:hvac_admin/core/models/message_history_filter.dart';
import 'package:hvac_admin/core/models/message_thread_summary.dart';
import 'package:hvac_admin/core/models/office_directory.dart';
import 'package:hvac_admin/core/models/office_message.dart';
import 'package:hvac_admin/core/utils/formatters.dart';
import 'package:hvac_admin/design_system/design_system.dart';
import 'package:hvac_admin/features/communication/message_thread_widgets.dart';
import 'package:hvac_admin/features/shared/widgets/paged_search_list.dart';
import 'package:provider/provider.dart';

class CommunicationPage extends StatefulWidget {
  const CommunicationPage({
    super.key,
    this.entityType,
    this.entityId,
    this.template,
    this.variableOverrides = const {},
  });

  final String? entityType;
  final String? entityId;
  final String? template;
  final Map<String, String> variableOverrides;

  @override
  State<CommunicationPage> createState() => _CommunicationPageState();
}

class _CommunicationPageState extends State<CommunicationPage> {
  CommunicationEntityType? _filter;
  CommunicationEntityType _composeType = CommunicationEntityType.customer;
  CommunicationChannel _channel = CommunicationChannel.sms;
  MessageTemplateKind? _templateKind;
  String? _entityId;
  CommunicationChannel? _channelFilter;
  MessageDateRangePreset _datePreset = MessageDateRangePreset.all;
  List<MessageThreadSummary> _recentThreads = const [];
  bool _loadingThreads = false;
  int _timelineRefresh = 0;
  late final TextEditingController _subject;
  late final TextEditingController _body;

  @override
  void initState() {
    super.initState();
    _subject = TextEditingController();
    _body = TextEditingController();
    _applyQuery();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await context.read<CustomerController>().load();
      await context.read<JobController>().loadDispatch();
      await context.read<CommunicationController>().loadWebhookFailures();
      await _loadRecentThreads();
      final kind = MessageTemplateKindX.tryParse(widget.template);
      if (kind != null) _applyTemplate(kind);
    });
  }

  @override
  void didUpdateWidget(covariant CommunicationPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entityType != widget.entityType ||
        oldWidget.entityId != widget.entityId ||
        oldWidget.template != widget.template) {
      setState(_applyQuery);
      final kind = MessageTemplateKindX.tryParse(widget.template);
      if (kind != null) _applyTemplate(kind);
    }
  }

  @override
  void dispose() {
    _subject.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _loadRecentThreads() async {
    setState(() => _loadingThreads = true);
    try {
      final threads = await context.read<CommunicationController>().fetchRecentThreads();
      if (mounted) setState(() => _recentThreads = threads);
    } finally {
      if (mounted) setState(() => _loadingThreads = false);
    }
  }

  MessageHistoryFilter? get _historyFilter {
    final base = _datePreset.toFilter(DateTime.now());
    if (_channelFilter == null && base == null) return null;
    return (base ?? const MessageHistoryFilter()).copyWith(
      channel: _channelFilter,
      clearChannel: _channelFilter == null,
    );
  }

  void _openThread(MessageThreadSummary thread) {
    setState(() {
      _filter = thread.entityType;
      _composeType = thread.entityType;
      _entityId = thread.entityId;
      _timelineRefresh++;
    });
  }

  void _applyQuery() {
    final type = _parseEntity(widget.entityType);
    _filter = type;
    if (type != null) _composeType = type;
    _entityId = widget.entityId;
  }

  CommunicationEntityType? _parseEntity(String? raw) => switch (raw) {
        'customer' => CommunicationEntityType.customer,
        'property' => CommunicationEntityType.property,
        'job' => CommunicationEntityType.job,
        _ => null,
      };

  String _filterLabel(CommunicationEntityType? type) => type?.label ?? 'All';

  String _entityLabel(
    CustomerController directory,
    JobController jobs,
    CommunicationEntityType type,
    String id,
  ) {
    return switch (type) {
      CommunicationEntityType.customer => directory.customerById(id)?.displayName ?? id,
      CommunicationEntityType.property => directory.propertyById(id)?.fullAddress ?? id,
      CommunicationEntityType.job => jobs.jobById(id)?.jobNumber ?? id,
    };
  }

  List<(String id, String label)> _options(CustomerController directory, JobController jobs) {
    return switch (_composeType) {
      CommunicationEntityType.customer => [
          for (final customer in directory.customers) (customer.id, customer.displayName),
        ],
      CommunicationEntityType.property => [
          for (final property in directory.properties) (property.id, property.fullAddress),
        ],
      CommunicationEntityType.job => [
          for (final job in jobs.jobs) (job.id, job.jobNumber),
        ],
    };
  }

  Map<String, String> _variablesFor(
    CustomerController directory,
    JobController jobs,
    CommunicationEntityType type,
    String entityId,
  ) {
    final base = switch (type) {
      CommunicationEntityType.job => () {
          final job = jobs.jobById(entityId) ?? directory.historyJobById(entityId);
          if (job == null) return <String, String>{};
          final property = directory.propertyById(job.propertyId);
          final customer = property == null ? null : directory.customerById(property.customerId);
          return MessageVariables.forJob(job: job, customer: customer, property: property);
        }(),
      CommunicationEntityType.customer => () {
          final customer = directory.customerById(entityId);
          if (customer == null) return <String, String>{};
          final property = customer.propertyIds.isEmpty
              ? null
              : directory.propertyById(customer.propertyIds.first);
          return MessageVariables.forCustomer(customer: customer, property: property);
        }(),
      CommunicationEntityType.property => () {
          final property = directory.propertyById(entityId);
          if (property == null) return <String, String>{};
          final customer = directory.customerById(property.customerId);
          if (customer == null) {
            return {
              'customer_name': 'Customer',
              'property_address': property.fullAddress,
              'job_number': '—',
              'service_date': formatDate(isoDate(DateTime.now())),
            };
          }
          return MessageVariables.forCustomer(customer: customer, property: property);
        }(),
    };
    return {...base, ...widget.variableOverrides};
  }

  String _toAddress(
    CustomerController directory,
    JobController jobs,
    CommunicationEntityType type,
    String entityId,
    String label,
  ) {
    return switch (type) {
      CommunicationEntityType.customer => directory.customerById(entityId)?.phone ?? label,
      CommunicationEntityType.job => () {
          final job = jobs.jobById(entityId) ?? directory.historyJobById(entityId);
          if (job == null) return label;
          final property = directory.propertyById(job.propertyId);
          final customer = property == null ? null : directory.customerById(property.customerId);
          return customer?.phone ?? customer?.email ?? label;
        }(),
      CommunicationEntityType.property => () {
          final property = directory.propertyById(entityId);
          final customer = property == null ? null : directory.customerById(property.customerId);
          return customer?.phone ?? customer?.email ?? label;
        }(),
    };
  }

  PreferredLanguage _preferredLanguageFor(
    CustomerController directory,
    JobController jobs,
    CommunicationEntityType type,
    String? entityId,
  ) {
    if (entityId == null || entityId.isEmpty) return PreferredLanguage.english;
    final customer = switch (type) {
      CommunicationEntityType.customer => directory.customerById(entityId),
      CommunicationEntityType.property => () {
          final property = directory.propertyById(entityId);
          return property == null ? null : directory.customerById(property.customerId);
        }(),
      CommunicationEntityType.job => () {
          final job = jobs.jobById(entityId) ?? directory.historyJobById(entityId);
          if (job == null) return null;
          final property = directory.propertyById(job.propertyId);
          return property == null ? null : directory.customerById(property.customerId);
        }(),
    };
    return customer?.preferredLanguage ?? PreferredLanguage.english;
  }

  Future<void> _send() async {
    final directory = context.read<CustomerController>();
    final jobs = context.read<JobController>();
    final options = _options(directory, jobs);
    final entityId = options.any((item) => item.$1 == _entityId)
        ? _entityId
        : (options.isEmpty ? null : options.first.$1);
    final body = _body.text.trim();
    if (body.isEmpty || entityId == null) return;

    final label = _entityLabel(directory, jobs, _composeType, entityId);
    final toAddress = _toAddress(directory, jobs, _composeType, entityId, label);
    final variables = _variablesFor(directory, jobs, _composeType, entityId);
    final locale = _preferredLanguageFor(directory, jobs, _composeType, entityId);
    final inbox = context.read<CommunicationController>();

    try {
      if (_templateKind != null) {
        await inbox.sendTemplate(
          kind: _templateKind!,
          entityType: _composeType,
          entityId: entityId,
          entityLabel: label,
          toAddress: toAddress,
          variables: variables,
          locale: locale,
        );
      } else {
        // Custom messages: send body as typed (no auto-translate).
        await inbox.send(
          channel: _channel,
          entityType: _composeType,
          entityId: entityId,
          entityLabel: label,
          body: body,
          subject: _channel == CommunicationChannel.email ? _subject.text : '',
          toAddress: toAddress,
        );
      }
      _body.clear();
      _subject.clear();
      setState(() => _timelineRefresh++);
      await _loadRecentThreads();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Message sent.')),
        );
      }
    } on MessagingSendException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          action: SnackBarAction(
            label: 'Retry',
            onPressed: () async {
              try {
                await inbox.retryLastSend();
                if (mounted) {
                  setState(() => _timelineRefresh++);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Message sent on retry.')),
                  );
                }
              } on MessagingSendException catch (retryError) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(retryError.message)),
                  );
                }
              }
            },
          ),
        ),
      );
    }
  }

  void _applyTemplate(MessageTemplateKind? kind, {PreferredLanguage? locale}) {
    setState(() {
      _templateKind = kind;
      if (kind == null) return;
      final directory = context.read<CustomerController>();
      final jobs = context.read<JobController>();
      final options = _options(directory, jobs);
      final entityId = options.any((item) => item.$1 == _entityId)
          ? _entityId
          : (options.isEmpty ? null : options.first.$1);
      final preferred = locale ?? _preferredLanguageFor(directory, jobs, _composeType, entityId);
      final template = MessageTemplateCatalog.byKind(kind, locale: preferred);
      _channel = template.channel;
      _subject.text = template.subject;
      _body.text = template.body;
    });
  }

  @override
  Widget build(BuildContext context) {
    final directory = context.watch<CustomerController>();
    final jobs = context.watch<JobController>();
    final inbox = context.watch<CommunicationController>();
    final options = _options(directory, jobs);
    final selectedId = options.any((item) => item.$1 == _entityId)
        ? _entityId
        : (options.isEmpty ? null : options.first.$1);
    final preferredLanguage = _preferredLanguageFor(directory, jobs, _composeType, selectedId);
    final wide = MediaQuery.sizeOf(context).width >= AppBreakpoints.mobile;

    final compose = _ComposeCard(
      type: _composeType,
      channel: _channel,
      templateKind: _templateKind,
      entityId: selectedId,
      options: options,
      subject: _subject,
      body: _body,
      sendError: inbox.sendError,
      preferredLanguage: preferredLanguage,
      onType: (value) => setState(() {
        _composeType = value;
        _entityId = null;
        if (_templateKind != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _applyTemplate(_templateKind);
          });
        }
      }),
      onChannel: (value) => setState(() => _channel = value),
      onTemplate: (kind) => _applyTemplate(kind),
      onEntity: (value) {
        setState(() => _entityId = value);
        if (_templateKind != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _applyTemplate(_templateKind);
          });
        }
      },
      onSend: _send,
      onRetry: inbox.canRetry ? () async => _send() : null,
    );
    final timeline = _PagedTimeline(
      refreshToken: _timelineRefresh,
      filter: _filter,
      entityId: _entityId,
      historyFilter: _historyFilter,
    );

    return Padding(
      key: const Key('communication-page'),
      padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SurfaceCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.entityId == null
                      ? 'Outbound SMS/email via server-side send-message edge function — no provider keys in the app.'
                      : 'Showing messages linked to this ${_filterLabel(_filter).toLowerCase()}.',
                  style: AppTypography.bodySmall,
                ),
                if (inbox.webhookFailures.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    '${inbox.webhookFailures.length} recent webhook failure(s).',
                    style: AppTypography.labelSmall.copyWith(color: AppColors.danger),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          MessageHistoryFiltersBar(
            channel: _channelFilter,
            datePreset: _datePreset,
            onChannel: (value) => setState(() {
              _channelFilter = value;
              _timelineRefresh++;
            }),
            onDatePreset: (value) => setState(() {
              _datePreset = value;
              _timelineRefresh++;
            }),
          ),
          if (_loadingThreads)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: LinearProgressIndicator(),
            )
          else if (_recentThreads.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            const SectionHeader(title: 'Recent threads'),
            const SizedBox(height: AppSpacing.sm),
            RecentMessageThreads(
              threads: _recentThreads,
              onOpenThread: _openThread,
              compact: true,
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              for (final option in const ['All', 'Customer', 'Property', 'Job'])
                FilterChip(
                  label: Text(option),
                  selected: _filterLabel(_filter) == option,
                  onSelected: (_) => setState(() {
                    _filter = switch (option) {
                      'Customer' => CommunicationEntityType.customer,
                      'Property' => CommunicationEntityType.property,
                      'Job' => CommunicationEntityType.job,
                      _ => null,
                    };
                    _entityId = null;
                    _timelineRefresh++;
                  }),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: wide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(flex: 3, child: timeline),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(flex: 2, child: compose),
                    ],
                  )
                : Column(
                    children: [
                      Expanded(flex: 3, child: timeline),
                      const SizedBox(height: AppSpacing.md),
                      Expanded(flex: 2, child: compose),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _PagedTimeline extends StatelessWidget {
  const _PagedTimeline({
    required this.refreshToken,
    required this.filter,
    this.entityId,
    this.historyFilter,
  });

  final int refreshToken;
  final CommunicationEntityType? filter;
  final String? entityId;
  final MessageHistoryFilter? historyFilter;

  @override
  Widget build(BuildContext context) {
    final inbox = context.watch<CommunicationController>();
    return SurfaceCard(
      padding: const EdgeInsets.all(12),
      child: PagedSearchList<OfficeMessage>(
        refreshToken: refreshToken,
        listKey: const Key('communication-timeline'),
        searchHint: 'Search name, phone, subject, or body',
        emptyTitle: 'No messages',
        emptyMessage: 'Send a template or custom message to start the timeline.',
        fetchPage: (offset, query) => inbox.fetchMessagesPage(
          offset: offset,
          search: query,
          entityType: filter,
          entityId: entityId,
          filter: historyFilter,
        ),
        itemBuilder: (context, message) => MessageBubble(message: message),
      ),
    );
  }
}

class _ComposeCard extends StatelessWidget {
  const _ComposeCard({
    required this.type,
    required this.channel,
    required this.templateKind,
    required this.entityId,
    required this.options,
    required this.subject,
    required this.body,
    required this.sendError,
    required this.preferredLanguage,
    required this.onType,
    required this.onChannel,
    required this.onTemplate,
    required this.onEntity,
    required this.onSend,
    this.onRetry,
  });

  final CommunicationEntityType type;
  final CommunicationChannel channel;
  final MessageTemplateKind? templateKind;
  final String? entityId;
  final List<(String id, String label)> options;
  final TextEditingController subject;
  final TextEditingController body;
  final String? sendError;
  final PreferredLanguage preferredLanguage;
  final ValueChanged<CommunicationEntityType> onType;
  final ValueChanged<CommunicationChannel> onChannel;
  final ValueChanged<MessageTemplateKind?> onTemplate;
  final ValueChanged<String> onEntity;
  final VoidCallback onSend;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SectionHeader(title: 'Compose'),
          if (sendError != null) ...[
            Text(sendError!, style: AppTypography.bodySmall.copyWith(color: AppColors.danger)),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.sm),
              AppSecondaryButton(label: 'Retry send', icon: Icons.refresh, onPressed: onRetry),
            ],
            const SizedBox(height: AppSpacing.md),
          ],
          StatusChip(
            key: const Key('compose-customer-language'),
            label: templateKind == null
                ? 'Custom message (typed as-is) · customer prefers ${preferredLanguage.label}'
                : 'Template language: ${preferredLanguage.label}',
            background: AppColors.primaryMuted,
            foreground: AppColors.primary,
          ),
          const SizedBox(height: AppSpacing.sm),
          InputDecorator(
            decoration: const InputDecoration(labelText: 'Template'),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<MessageTemplateKind?>(
                key: const Key('compose-template'),
                value: templateKind,
                isExpanded: true,
                items: [
                  const DropdownMenuItem<MessageTemplateKind?>(value: null, child: Text('Custom message')),
                  for (final kind in MessageTemplateKind.values)
                    DropdownMenuItem(value: kind, child: Text(kind.label)),
                ],
                onChanged: onTemplate,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          InputDecorator(
            decoration: const InputDecoration(labelText: 'Link to'),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<CommunicationEntityType>(
                key: const Key('compose-entity-type'),
                value: type,
                isExpanded: true,
                items: [
                  for (final item in CommunicationEntityType.values)
                    DropdownMenuItem(value: item, child: Text(item.label)),
                ],
                onChanged: (value) {
                  if (value != null) onType(value);
                },
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          InputDecorator(
            decoration: const InputDecoration(labelText: 'Record'),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                key: const Key('compose-entity-id'),
                value: entityId,
                isExpanded: true,
                items: [
                  for (final option in options)
                    DropdownMenuItem(value: option.$1, child: Text(option.$2, overflow: TextOverflow.ellipsis)),
                ],
                onChanged: (value) {
                  if (value != null) onEntity(value);
                },
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              FilterChip(
                label: const Text('SMS'),
                selected: channel == CommunicationChannel.sms,
                onSelected: (_) => onChannel(CommunicationChannel.sms),
              ),
              FilterChip(
                label: const Text('Email'),
                selected: channel == CommunicationChannel.email,
                onSelected: (_) => onChannel(CommunicationChannel.email),
              ),
            ],
          ),
          if (channel == CommunicationChannel.email) ...[
            const SizedBox(height: AppSpacing.md),
            AppTextField(controller: subject, label: 'Subject'),
          ],
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            key: const Key('compose-body'),
            controller: body,
            minLines: 4,
            maxLines: 8,
            style: const TextStyle(fontSize: 15),
            decoration: const InputDecoration(
              labelText: 'Message',
              hintText: 'Message body (templates use {{variables}})',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppPrimaryButton(
            key: const Key('send-message'),
            label: 'Send ${channel.label}',
            icon: Icons.send_outlined,
            expanded: true,
            onPressed: onSend,
          ),
        ],
      ),
    ),
    );
  }
}

String communicationPath({
  required CommunicationEntityType entityType,
  required String entityId,
  MessageTemplateKind? template,
  Map<String, String>? variables,
}) {
  final params = <String, String>{
    'entity': switch (entityType) {
      CommunicationEntityType.customer => 'customer',
      CommunicationEntityType.property => 'property',
      CommunicationEntityType.job => 'job',
    },
    'id': entityId,
    if (template != null) 'template': template.id,
    if (variables != null)
      for (final entry in variables.entries)
        if (entry.value.isNotEmpty) entry.key: entry.value,
  };
  return Uri(path: '/communication', queryParameters: params).toString();
}
