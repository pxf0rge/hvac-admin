import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hvac_admin/core/controllers/document_template_controller.dart';
import 'package:hvac_admin/core/controllers/settings_controller.dart';
import 'package:hvac_admin/core/documents/document_renderer.dart';
import 'package:hvac_admin/core/documents/document_sample_data.dart';
import 'package:hvac_admin/core/enums/admin_module.dart';
import 'package:hvac_admin/core/models/document_template.dart';
import 'package:hvac_admin/core/utils/formatters.dart';
import 'package:hvac_admin/data/datasources/mock_document_templates.dart';
import 'package:hvac_admin/design_system/design_system.dart';
import 'package:provider/provider.dart';

class TemplateEditorPage extends StatefulWidget {
  const TemplateEditorPage({super.key, this.templateId});

  final String? templateId;

  @override
  State<TemplateEditorPage> createState() => _TemplateEditorPageState();
}

class _TemplateEditorPageState extends State<TemplateEditorPage> {
  late final TextEditingController _title;
  late final TextEditingController _body;
  List<DocumentFieldDef> _fields = const [];
  int _viewingVersion = 0;
  bool _ready = false;

  bool get _isNew => widget.templateId == null;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController();
    _body = TextEditingController();
    _body.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final library = context.read<DocumentTemplateController>();
      await Future.wait([
        library.load(),
        context.read<SettingsController>().load(),
      ]);
      if (!mounted) return;
      _hydrate(library.templateById(widget.templateId ?? ''));
    });
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  void _hydrate(ManagedDocumentTemplate? template) {
    if (template == null) {
      _title.text = 'Untitled template';
      _body.text = 'Customer {{customer_name}} agrees to service at {{property_address}}.';
      _fields = [MockDocumentTemplates.customerName, MockDocumentTemplates.propertyAddress];
      _viewingVersion = 1;
    } else {
      final version = template.current;
      _title.text = template.title;
      _body.text = version.body.trim();
      _fields = [...version.fields];
      _viewingVersion = version.version;
    }
    setState(() => _ready = true);
  }

  void _loadVersion(DocumentTemplateVersion version) {
    setState(() {
      _body.text = version.body.trim();
      _fields = [...version.fields];
      _viewingVersion = version.version;
    });
  }

  Future<void> _save({required bool newVersion}) async {
    final library = context.read<DocumentTemplateController>();
    if (_isNew) {
      final created = await library.create(title: _title.text, body: _body.text, fields: _fields);
      if (mounted) context.go('${AdminModule.documents.path}/${created.id}');
      return;
    }
    final id = widget.templateId!;
    if (newVersion) {
      await library.saveNewVersion(id: id, title: _title.text, body: _body.text, fields: _fields);
    } else {
      await library.saveCurrent(id: id, title: _title.text, body: _body.text, fields: _fields);
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(newVersion ? 'New version published.' : 'Template saved.')),
    );
    setState(() {
      _viewingVersion = library.templateById(id)?.currentVersion ?? _viewingVersion;
    });
  }

  void _addField(DocumentFieldDef field) {
    if (_fields.any((item) => item.key == field.key)) return;
    setState(() => _fields = [..._fields, field]);
  }

  String _previewText(Map<String, String> globalVariables) => DocumentRenderer.render(
        body: _body.text,
        fields: _fields,
        fieldValues: DocumentSampleData.valuesFor(_fields),
        globalVariables: globalVariables,
      );

  @override
  Widget build(BuildContext context) {
    final library = context.watch<DocumentTemplateController>();
    final globalVariables = context.watch<SettingsController>().documentVariables;
    final template = _isNew ? null : library.templateById(widget.templateId!);
    if (!_ready || (library.isLoading && !_isNew && template == null)) {
      return const LoadingState(message: 'Loading template…');
    }
    if (!_isNew && template == null) {
      return const EmptyState(title: 'Template not found', icon: Icons.description_outlined);
    }

    final latest = template?.currentVersion ?? 1;
    final editingLatest = _isNew || _viewingVersion == latest;

    return SingleChildScrollView(
      key: const Key('template-editor'),
      padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.xxxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              AppTextAction(
                label: 'Back to library',
                onPressed: () => context.go(AdminModule.documents.path),
              ),
              const Spacer(),
              if (!_isNew)
                AppSecondaryButton(
                  key: const Key('save-template-version'),
                  label: 'Publish new version',
                  onPressed: () => _save(newVersion: true),
                ),
              const SizedBox(width: AppSpacing.sm),
              AppPrimaryButton(
                key: const Key('save-template'),
                label: _isNew ? 'Create template' : 'Save',
                onPressed: editingLatest || _isNew ? () => _save(newVersion: false) : null,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppTextField(key: const Key('template-title'), controller: _title, label: 'Title'),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  key: const Key('template-body'),
                  controller: _body,
                  maxLines: 10,
                  style: const TextStyle(fontSize: 15),
                  decoration: const InputDecoration(
                    labelText: 'Template body',
                    hintText: 'Use {{field_key}} placeholders. Stays in professional English.',
                    alignLabelWithHint: true,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          SectionHeader(
            title: 'Fields',
            trailing: PopupMenuButton<DocumentFieldDef>(
              key: const Key('add-template-field'),
              tooltip: 'Add field',
              onSelected: _addField,
              itemBuilder: (context) => [
                for (final field in MockDocumentTemplates.fieldCatalog)
                  PopupMenuItem(value: field, child: Text(field.label)),
              ],
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text('Add field'),
              ),
            ),
          ),
          SurfaceCard(
            child: Column(
              children: [
                if (_fields.isEmpty)
                  const Text('Add at least one field for technician forms.', style: AppTypography.bodySmall)
                else
                  for (var i = 0; i < _fields.length; i++)
                    _FieldRow(
                      field: _fields[i],
                      onRequired: (value) => setState(() {
                        _fields[i] = _fields[i].copyWith(required: value);
                      }),
                      onRemove: () => setState(() {
                        _fields = [for (var n = 0; n < _fields.length; n++) if (n != i) _fields[n]];
                      }),
                    ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          const SectionHeader(title: 'Preview with sample data'),
          SurfaceCard(
            key: const Key('template-preview'),
            child: Text(_previewText(globalVariables), style: AppTypography.bodyMedium),
          ),
          if (template != null) ...[
            const SizedBox(height: AppSpacing.xl),
            const SectionHeader(title: 'Version history'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final version in template.versions)
                  FilterChip(
                    key: Key('template-version-${version.version}'),
                    selected: version.version == _viewingVersion,
                    label: Text('v${version.version}  ·  ${formatDate(version.createdAt)}'),
                    onSelected: (_) => _loadVersion(version),
                  ),
              ],
            ),
            if (template.versions.any((item) => item.version == _viewingVersion && item.note.isNotEmpty))
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  template.versions.firstWhere((item) => item.version == _viewingVersion).note,
                  style: AppTypography.bodySmall,
                ),
              ),
            const SizedBox(height: AppSpacing.md),
            Text('Editing version $_viewingVersion of $latest', style: AppTypography.labelMedium),
          ],
        ],
      ),
    );
  }
}

class _FieldRow extends StatelessWidget {
  const _FieldRow({
    required this.field,
    required this.onRequired,
    required this.onRemove,
  });

  final DocumentFieldDef field;
  final ValueChanged<bool> onRequired;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(field.label, style: AppTypography.titleMedium),
                Text('{{${field.key}}}', style: AppTypography.labelSmall),
              ],
            ),
          ),
          FilterChip(
            label: Text(field.required ? 'Required' : 'Optional'),
            selected: field.required,
            onSelected: onRequired,
          ),
          IconButton(onPressed: onRemove, icon: const Icon(Icons.close)),
        ],
      ),
    );
  }
}
