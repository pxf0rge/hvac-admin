import 'package:flutter/foundation.dart';
import 'package:hvac_admin/core/enums/domain_enums.dart';
import 'package:hvac_admin/core/models/document_template.dart';
import 'package:hvac_admin/data/repositories/document_template_repository.dart';

class DocumentTemplateController extends ChangeNotifier {
  DocumentTemplateController(this._repository);

  final DocumentTemplateRepository _repository;
  bool _loading = false;
  String? _loadError;
  List<ManagedDocumentTemplate> _templates = const [];
  int _nextCustom = 1;
  int _refreshToken = 0;

  bool get isLoading => _loading;
  String? get loadError => _loadError;
  List<ManagedDocumentTemplate> get templates => List.unmodifiable(_templates);
  int get refreshToken => _refreshToken;

  ManagedDocumentTemplate? templateById(String id) {
    for (final template in _templates) {
      if (template.id == id) return template;
    }
    return null;
  }

  List<ManagedDocumentTemplate> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return templates;
    return [
      for (final template in _templates)
        if (template.title.toLowerCase().contains(q) || template.id.toLowerCase().contains(q)) template,
    ];
  }

  Future<void> load({bool force = false}) async {
    if (_loading) return;
    if (!force && _templates.isNotEmpty && _loadError == null) return;
    _loading = true;
    _loadError = null;
    notifyListeners();
    try {
      _templates = [...await _repository.getTemplates()];
      if (force) _refreshToken += 1;
    } catch (error, stack) {
      _loadError = error.toString();
      debugPrint('DocumentTemplateController.load failed: $error\n$stack');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> toggleActive(String id) async {
    final current = templateById(id);
    if (current == null) return;
    await _commit(
      current.copyWith(
        status: current.isActive ? DocumentTemplateStatus.draft : DocumentTemplateStatus.active,
        lastUpdated: DateTime.now().toIso8601String(),
      ),
    );
  }

  Future<void> saveCurrent({
    required String id,
    required String title,
    required String body,
    required List<DocumentFieldDef> fields,
  }) async {
    final current = templateById(id);
    if (current == null || current.versions.isEmpty) return;
    final versions = [...current.versions];
    versions[versions.length - 1] = current.current.copyWith(body: body, fields: fields);
    await _commit(
      current.copyWith(title: title, lastUpdated: DateTime.now().toIso8601String(), versions: versions),
    );
  }

  Future<void> saveNewVersion({
    required String id,
    required String title,
    required String body,
    required List<DocumentFieldDef> fields,
    String note = 'Office revision',
  }) async {
    final current = templateById(id);
    if (current == null) return;
    final next = DocumentTemplateVersion(
      version: current.currentVersion + 1,
      createdAt: DateTime.now().toIso8601String(),
      body: body,
      fields: fields,
      note: note,
    );
    await _commit(
      current.copyWith(
        title: title,
        lastUpdated: next.createdAt,
        versions: [...current.versions, next],
      ),
    );
  }

  Future<ManagedDocumentTemplate> create({
    required String title,
    required String body,
    required List<DocumentFieldDef> fields,
  }) async {
    final template = ManagedDocumentTemplate(
      id: 'tpl_custom_${_nextCustom++}',
      title: title.trim().isEmpty ? 'Untitled template' : title.trim(),
      status: DocumentTemplateStatus.draft,
      lastUpdated: DateTime.now().toIso8601String(),
      versions: [
        DocumentTemplateVersion(
          version: 1,
          createdAt: DateTime.now().toIso8601String(),
          body: body,
          fields: fields,
          note: 'Created in office library',
        ),
      ],
    );
    await _commit(template);
    return template;
  }

  Future<void> _commit(ManagedDocumentTemplate template) async {
    final saved = await _repository.save(template);
    final index = _templates.indexWhere((item) => item.id == saved.id);
    if (index < 0) {
      _templates = [..._templates, saved];
    } else {
      final next = [..._templates];
      next[index] = saved;
      _templates = next;
    }
    _refreshToken += 1;
    notifyListeners();
  }
}
