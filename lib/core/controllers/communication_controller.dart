import 'package:flutter/foundation.dart';
import 'package:hvac_admin/core/enums/domain_enums.dart';
import 'package:hvac_admin/core/messaging/message_dispatch_service.dart';
import 'package:hvac_admin/core/messaging/message_thread_grouper.dart';
import 'package:hvac_admin/core/messaging/message_templates.dart';
import 'package:hvac_admin/core/models/message_history_filter.dart';
import 'package:hvac_admin/core/models/message_thread_summary.dart';
import 'package:hvac_admin/core/messaging/messaging_send_exception.dart';
import 'package:hvac_admin/core/models/message_webhook_failure.dart';
import 'package:hvac_admin/core/models/office_message.dart';
import 'package:hvac_admin/data/pagination/paged_result.dart';
import 'package:hvac_admin/data/repositories/communication_repository.dart';

class PendingOutboundMessage {
  const PendingOutboundMessage({
    required this.channel,
    required this.entityType,
    required this.entityId,
    required this.entityLabel,
    required this.toAddress,
    required this.body,
    this.subject = '',
    this.templateKind,
    this.variables = const {},
    this.locale = PreferredLanguage.english,
  });

  final CommunicationChannel channel;
  final CommunicationEntityType entityType;
  final String entityId;
  final String entityLabel;
  final String toAddress;
  final String body;
  final String subject;
  final MessageTemplateKind? templateKind;
  final Map<String, String> variables;
  final PreferredLanguage locale;
}

class CommunicationController extends ChangeNotifier {
  CommunicationController(this._repository, {MessageDispatchService? dispatch}) : _dispatch = dispatch;

  final CommunicationRepository _repository;
  final MessageDispatchService? _dispatch;
  bool _loading = false;
  List<OfficeMessage> _messages = const [];
  List<MessageWebhookFailure> _webhookFailures = const [];
  String? _sendError;
  PendingOutboundMessage? _pendingRetry;
  int _refreshToken = 0;

  bool get isLoading => _loading;
  List<OfficeMessage> get messages => List.unmodifiable(_messages);
  List<MessageWebhookFailure> get webhookFailures => List.unmodifiable(_webhookFailures);
  String? get sendError => _sendError;
  bool get canRetry => _pendingRetry != null;
  int get refreshToken => _refreshToken;

  Future<void> load({
    bool force = false,
    CommunicationEntityType? entityType,
    String? entityId,
  }) async {
    if (!force && _messages.isNotEmpty && entityType == null && entityId == null) return;
    _loading = true;
    notifyListeners();
    try {
      _messages = [...await _repository.getMessages(entityType: entityType, entityId: entityId)];
      _webhookFailures = [...await _repository.getWebhookFailures()];
      if (force) _refreshToken += 1;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadWebhookFailures() async {
    _webhookFailures = [...await _repository.getWebhookFailures()];
    notifyListeners();
  }

  Future<OfficeMessage> send({
    required CommunicationChannel channel,
    required CommunicationEntityType entityType,
    required String entityId,
    required String entityLabel,
    required String body,
    String subject = '',
    String toAddress = '',
  }) async {
    final pending = PendingOutboundMessage(
      channel: channel,
      entityType: entityType,
      entityId: entityId,
      entityLabel: entityLabel,
      toAddress: toAddress.isEmpty ? entityLabel : toAddress,
      body: body,
      subject: subject,
    );
    return _dispatchOutbound(pending);
  }

  Future<OfficeMessage> sendTemplate({
    required MessageTemplateKind kind,
    required CommunicationEntityType entityType,
    required String entityId,
    required String entityLabel,
    required String toAddress,
    required Map<String, String> variables,
    PreferredLanguage locale = PreferredLanguage.english,
  }) async {
    final template = MessageTemplateCatalog.byKind(kind, locale: locale);
    final pending = PendingOutboundMessage(
      channel: template.channel,
      entityType: entityType,
      entityId: entityId,
      entityLabel: entityLabel,
      toAddress: toAddress,
      body: template.renderBody(variables),
      subject: template.renderSubject(variables),
      templateKind: kind,
      variables: variables,
      locale: locale,
    );
    return _dispatchOutbound(pending);
  }

  Future<OfficeMessage> retryLastSend() async {
    final pending = _pendingRetry;
    if (pending == null) {
      throw StateError('No failed send to retry');
    }
    return _dispatchOutbound(pending);
  }

  void clearSendError() {
    _sendError = null;
    notifyListeners();
  }

  Future<OfficeMessage> _dispatchOutbound(PendingOutboundMessage pending) async {
    _sendError = null;
    _pendingRetry = pending;
    notifyListeners();
    try {
      final OfficeMessage saved;
      final dispatch = _dispatch;
      if (dispatch == null) {
        throw StateError('Message dispatch is not configured');
      }
      if (pending.templateKind != null) {
        saved = await dispatch.sendTemplate(
          kind: pending.templateKind!,
          entityType: pending.entityType,
          entityId: pending.entityId,
          entityLabel: pending.entityLabel,
          toAddress: pending.toAddress,
          variables: pending.variables,
          locale: pending.locale,
        );
      } else {
        saved = await dispatch.sendCustom(
          channel: pending.channel,
          entityType: pending.entityType,
          entityId: pending.entityId,
          entityLabel: pending.entityLabel,
          toAddress: pending.toAddress,
          body: pending.body,
          subject: pending.subject,
        );
      }
      _messages = [saved, ..._messages.where((item) => item.id != saved.id)];
      _pendingRetry = null;
      _refreshToken += 1;
      notifyListeners();
      return saved;
    } on MessagingSendException catch (error) {
      _sendError = error.message;
      notifyListeners();
      rethrow;
    }
  }

  Future<PagedResult<OfficeMessage>> fetchMessagesPage({
    required int offset,
    String? search,
    CommunicationEntityType? entityType,
    String? entityId,
    List<MessageEntityRef>? entities,
    MessageHistoryFilter? filter,
  }) {
    return _repository.getMessagesPage(
      offset: offset,
      search: _cleanSearch(search),
      entityType: entityType,
      entityId: entityId,
      entities: entities,
      filter: filter,
    );
  }

  Future<List<MessageThreadSummary>> fetchRecentThreads({int limit = 12}) async {
    final messages = await _repository.getMessages(limit: 250);
    return MessageThreadGrouper.recentThreads(messages, limit: limit);
  }

  String? _cleanSearch(String? search) {
    final trimmed = search?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }
}
