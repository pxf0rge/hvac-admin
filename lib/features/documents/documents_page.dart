import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hvac_admin/core/controllers/document_template_controller.dart';
import 'package:hvac_admin/core/enums/admin_module.dart';
import 'package:hvac_admin/core/utils/formatters.dart';
import 'package:hvac_admin/design_system/design_system.dart';
import 'package:hvac_admin/features/documents/document_template_widgets.dart';
import 'package:hvac_admin/features/shared/widgets/mobile_list_tile.dart';
import 'package:provider/provider.dart';

class DocumentsPage extends StatefulWidget {
  const DocumentsPage({super.key});

  @override
  State<DocumentsPage> createState() => _DocumentsPageState();
}

class _DocumentsPageState extends State<DocumentsPage> {
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<DocumentTemplateController>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final library = context.watch<DocumentTemplateController>();
    final templates = library.search(_query);

    if (library.isLoading && library.templates.isEmpty) {
      return const LoadingState(message: 'Loading templates…');
    }

    if (library.loadError != null && library.templates.isEmpty) {
      return ErrorState(message: library.loadError!, onRetry: () => library.load(force: true));
    }

    return Padding(
      key: const Key('documents-page'),
      padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Document templates', style: AppTypography.headlineMedium),
                    SizedBox(height: AppSpacing.xs),
                    Text(
                      'Reusable English forms for technicians — updates publish without rebuilding the field app.',
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ),
              ),
              AppPrimaryButton(
                label: 'New template',
                icon: Icons.add,
                onPressed: () => context.go('${AdminModule.documents.path}/new'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AppSearchField(
            hint: 'Search templates',
            onChanged: (value) => setState(() => _query = value),
          ),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: templates.isEmpty
                ? const EmptyState(
                    key: Key('documents-empty'),
                    title: 'No templates',
                    message: 'Create an office document template.',
                    icon: Icons.description_outlined,
                  )
                : ListView.separated(
                    key: const Key('template-list'),
                    itemCount: templates.length,
                    separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final template = templates[index];
                      return Row(
                        children: [
                          Expanded(
                            child: MobileListTile(
                              key: Key('template-row-${template.id}'),
                              title: template.title,
                              subtitle:
                                  '${template.requiredFieldCount} required fields  ·  ${template.current.fields.length} total',
                              meta:
                                  'Version ${template.currentVersion}  ·  Updated ${formatDate(template.lastUpdated)}',
                              trailing: TemplateStatusChip(status: template.status),
                              onTap: () => context.go('${AdminModule.documents.path}/${template.id}'),
                            ),
                          ),
                          Switch(
                            key: Key('toggle-template-${template.id}'),
                            value: template.isActive,
                            onChanged: (_) => library.toggleActive(template.id),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
