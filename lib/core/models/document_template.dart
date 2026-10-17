import 'package:hvac_admin/core/enums/domain_enums.dart';

class DocumentFieldDef {
  const DocumentFieldDef({
    required this.key,
    required this.label,
    this.required = true,
    this.autoFillFrom,
    this.multiline = false,
  });

  final String key;
  final String label;
  final bool required;
  final String? autoFillFrom;
  final bool multiline;

  DocumentFieldDef copyWith({
    String? key,
    String? label,
    bool? required,
    String? autoFillFrom,
    bool? multiline,
  }) {
    return DocumentFieldDef(
      key: key ?? this.key,
      label: label ?? this.label,
      required: required ?? this.required,
      autoFillFrom: autoFillFrom ?? this.autoFillFrom,
      multiline: multiline ?? this.multiline,
    );
  }
}

class DocumentTemplateVersion {
  const DocumentTemplateVersion({
    this.id,
    required this.version,
    required this.createdAt,
    required this.body,
    required this.fields,
    this.note = '',
  });

  final String? id;
  final int version;
  final String createdAt;
  final String body;
  final List<DocumentFieldDef> fields;
  final String note;

  DocumentTemplateVersion copyWith({
    String? id,
    String? body,
    List<DocumentFieldDef>? fields,
    String? note,
  }) {
    return DocumentTemplateVersion(
      id: id ?? this.id,
      version: version,
      createdAt: createdAt,
      body: body ?? this.body,
      fields: fields ?? this.fields,
      note: note ?? this.note,
    );
  }
}

class ManagedDocumentTemplate {
  const ManagedDocumentTemplate({
    required this.id,
    required this.title,
    required this.status,
    required this.lastUpdated,
    required this.versions,
  });

  final String id;
  final String title;
  final DocumentTemplateStatus status;
  final String lastUpdated;
  final List<DocumentTemplateVersion> versions;

  int get currentVersion => versions.isEmpty ? 0 : versions.last.version;

  DocumentTemplateVersion get current => versions.last;

  bool get isActive => status == DocumentTemplateStatus.active;

  int get requiredFieldCount => current.fields.where((field) => field.required).length;

  ManagedDocumentTemplate copyWith({
    String? title,
    DocumentTemplateStatus? status,
    String? lastUpdated,
    List<DocumentTemplateVersion>? versions,
  }) {
    return ManagedDocumentTemplate(
      id: id,
      title: title ?? this.title,
      status: status ?? this.status,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      versions: versions ?? this.versions,
    );
  }
}
