class InternalThread {
  const InternalThread({
    required this.id,
    required this.technicianId,
    required this.technicianName,
    this.jobId,
    this.jobNumber = '',
    this.subject = '',
    this.lastMessagePreview = '',
    this.lastMessageAt = '',
    this.unreadCount = 0,
  });

  final String id;
  final String technicianId;
  final String technicianName;
  final String? jobId;
  final String jobNumber;
  final String subject;
  final String lastMessagePreview;
  final String lastMessageAt;
  final int unreadCount;

  String get title {
    if (subject.trim().isNotEmpty) return subject.trim();
    if (jobNumber.isNotEmpty) return '$technicianName · $jobNumber';
    return technicianName;
  }
}

enum InternalSenderKind { office, technician }

class InternalMessage {
  const InternalMessage({
    required this.id,
    required this.threadId,
    required this.senderProfileId,
    required this.senderKind,
    required this.body,
    required this.createdAt,
    this.senderName = '',
  });

  final String id;
  final String threadId;
  final String senderProfileId;
  final InternalSenderKind senderKind;
  final String body;
  final String createdAt;
  final String senderName;

  bool get fromOffice => senderKind == InternalSenderKind.office;
}
