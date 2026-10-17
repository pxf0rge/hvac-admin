import 'package:hvac_admin/core/models/internal_message.dart';
import 'package:hvac_admin/data/mappers/mapper_helpers.dart';
import 'package:hvac_admin/data/repositories/internal_messaging_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseInternalMessagingRepository implements InternalMessagingRepository {
  SupabaseInternalMessagingRepository(this._client);

  final SupabaseClient _client;

  static const _threadSelect =
      'id, technician_id, job_id, subject, last_message_at, created_at, '
      'technicians(first_name, last_name), jobs(job_number)';

  String? get _uid => _client.auth.currentUser?.id;

  @override
  Future<List<InternalThread>> listThreads() async {
    final uid = _uid;
    final rows = await _client
        .from('internal_threads')
        .select(_threadSelect)
        .order('last_message_at', ascending: false);

    final reads = <String, String>{};
    if (uid != null) {
      final readRows = await _client
          .from('internal_thread_reads')
          .select('thread_id, last_read_at')
          .eq('profile_id', uid);
      for (final row in readRows) {
        reads[MapperHelpers.uuid(row['thread_id'])] = MapperHelpers.isoTimestamp(row['last_read_at']);
      }
    }

    final threads = <InternalThread>[];
    for (final raw in rows) {
      final row = MapperHelpers.row(raw);
      final id = MapperHelpers.uuid(row['id']);
      final preview = await _latestPreview(id);
      final unread = await _unreadForThread(id, reads[id]);
      threads.add(_threadFromRow(row, preview: preview, unread: unread));
    }
    return threads;
  }

  @override
  Future<List<InternalMessage>> listMessages(String threadId) async {
    final rows = await _client
        .from('internal_messages')
        .select('id, thread_id, sender_profile_id, sender_kind, body, created_at, profiles(first_name, last_name)')
        .eq('thread_id', threadId)
        .order('created_at');
    return [for (final row in rows) _messageFromRow(MapperHelpers.row(row))];
  }

  @override
  Future<InternalThread> getOrCreateThread({
    required String technicianId,
    String? jobId,
    String subject = '',
  }) async {
    var query = _client.from('internal_threads').select(_threadSelect).eq('technician_id', technicianId);
    if (jobId == null || jobId.isEmpty) {
      query = query.isFilter('job_id', null);
    } else {
      query = query.eq('job_id', jobId);
    }
    final existing = await query.maybeSingle();
    if (existing != null) {
      return _threadFromRow(MapperHelpers.row(existing));
    }

    final payload = <String, dynamic>{
      'technician_id': technicianId,
      'subject': subject.trim(),
      if (_uid != null) 'created_by': _uid,
      if (jobId != null && jobId.isNotEmpty) 'job_id': jobId,
    };
    final row = await _client.from('internal_threads').insert(payload).select(_threadSelect).single();
    return _threadFromRow(MapperHelpers.row(row));
  }

  @override
  Future<InternalMessage> sendMessage({
    required String threadId,
    required String body,
  }) async {
    final uid = _uid;
    if (uid == null) throw StateError('Not authenticated');
    final text = body.trim();
    if (text.isEmpty) throw ArgumentError('Message body is required');

    final row = await _client
        .from('internal_messages')
        .insert({
          'thread_id': threadId,
          'sender_profile_id': uid,
          'sender_kind': 'office',
          'body': text,
        })
        .select('id, thread_id, sender_profile_id, sender_kind, body, created_at, profiles(first_name, last_name)')
        .single();
    await markRead(threadId);
    return _messageFromRow(MapperHelpers.row(row));
  }

  @override
  Future<void> markRead(String threadId) async {
    final uid = _uid;
    if (uid == null) return;
    await _client.from('internal_thread_reads').upsert({
      'thread_id': threadId,
      'profile_id': uid,
      'last_read_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  @override
  Future<int> unreadCount() async {
    final threads = await listThreads();
    return threads.fold<int>(0, (sum, t) => sum + t.unreadCount);
  }

  Future<String> _latestPreview(String threadId) async {
    final row = await _client
        .from('internal_messages')
        .select('body')
        .eq('thread_id', threadId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
    return MapperHelpers.str(row?['body']);
  }

  Future<int> _unreadForThread(String threadId, String? lastReadAt) async {
    final uid = _uid;
    var query = _client
        .from('internal_messages')
        .select('id')
        .eq('thread_id', threadId)
        .neq('sender_kind', 'office');
    if (uid != null) {
      query = query.neq('sender_profile_id', uid);
    }
    if (lastReadAt != null && lastReadAt.isNotEmpty) {
      query = query.gt('created_at', lastReadAt);
    }
    final rows = await query;
    return rows.length;
  }

  InternalThread _threadFromRow(
    Map<String, dynamic> row, {
    String preview = '',
    int unread = 0,
  }) {
    final tech = row['technicians'];
    var techName = 'Technician';
    if (tech is Map) {
      final name =
          '${MapperHelpers.str(tech['first_name'])} ${MapperHelpers.str(tech['last_name'])}'.trim();
      if (name.isNotEmpty) techName = name;
    }
    final job = row['jobs'];
    var jobNumber = '';
    if (job is Map) jobNumber = MapperHelpers.str(job['job_number']);

    return InternalThread(
      id: MapperHelpers.uuid(row['id']),
      technicianId: MapperHelpers.uuid(row['technician_id']),
      technicianName: techName,
      jobId: MapperHelpers.strOrNull(row['job_id']),
      jobNumber: jobNumber,
      subject: MapperHelpers.str(row['subject']),
      lastMessagePreview: preview,
      lastMessageAt: MapperHelpers.isoTimestamp(row['last_message_at']),
      unreadCount: unread,
    );
  }

  InternalMessage _messageFromRow(Map<String, dynamic> row) {
    final profile = row['profiles'];
    var senderName = '';
    if (profile is Map) {
      senderName =
          '${MapperHelpers.str(profile['first_name'])} ${MapperHelpers.str(profile['last_name'])}'.trim();
    }
    final kind = MapperHelpers.str(row['sender_kind']) == 'technician'
        ? InternalSenderKind.technician
        : InternalSenderKind.office;
    return InternalMessage(
      id: MapperHelpers.uuid(row['id']),
      threadId: MapperHelpers.uuid(row['thread_id']),
      senderProfileId: MapperHelpers.uuid(row['sender_profile_id']),
      senderKind: kind,
      body: MapperHelpers.str(row['body']),
      createdAt: MapperHelpers.isoTimestamp(row['created_at']),
      senderName: senderName,
    );
  }
}
