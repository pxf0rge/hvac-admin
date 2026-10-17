import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hvac_admin/core/controllers/management_auth_controller.dart';
import 'package:hvac_admin/core/controllers/settings_controller.dart';
import 'package:hvac_admin/core/enums/admin_module.dart';
import 'package:hvac_admin/core/l10n/admin_strings.dart';
import 'package:hvac_admin/design_system/design_system.dart';
import 'package:hvac_admin/features/shared/widgets/language_toggle.dart';
import 'package:provider/provider.dart';

class AdminShell extends StatelessWidget {
  const AdminShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<ManagementAuthController>();
    final settings = context.watch<SettingsController>();
    final strings = adminStrings(context);
    final path = GoRouterState.of(context).uri.path;
    final wide = MediaQuery.sizeOf(context).width >= AppBreakpoints.mobile;
    final visibleModules = [
      for (final module in AdminModule.values)
        if (auth.canOpen(module)) module,
    ];

    final sidebar = _AdminSidebar(
      modules: visibleModules,
      currentPath: path,
      companyName: _companyName(settings),
      sessionName: auth.session?.displayName ?? '',
      roleLabel: strings.role(auth.role),
      strings: strings,
      onSignOut: () async {
        await auth.signOut();
        if (context.mounted) context.go('/login');
      },
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_titleForPath(path, strings)),
        automaticallyImplyLeading: !wide,
        actions: [
          IconButton(
            tooltip: strings.search,
            icon: const Icon(Icons.search),
            onPressed: () => context.go('/search'),
          ),
        ],
      ),
      drawer: wide ? null : Drawer(backgroundColor: AppColors.sidebarBg, child: sidebar),
      body: Row(
        children: [
          if (wide)
            SizedBox(
              width: 248,
              child: Material(
                color: AppColors.sidebarBg,
                child: sidebar,
              ),
            ),
          Expanded(
            child: ColoredBox(
              color: AppColors.background,
              child: child,
            ),
          ),
        ],
      ),
    );
  }

  String _companyName(SettingsController settings) {
    final name = settings.company?.companyName.trim() ?? '';
    return name.isEmpty ? 'Arctic HVAC Solutions' : name;
  }

  String _titleForPath(String path, AdminStrings strings) {
    for (final module in AdminModule.values) {
      if (module.supportsDetailRoute && path.startsWith('${module.path}/')) {
        return strings.detailTitle(module);
      }
    }
    if (path == '/search') return strings.search;
    if (path == '/access-denied') return strings.accessDenied;
    for (final module in AdminModule.values) {
      if (path == module.path) return strings.module(module);
    }
    return strings.appTitle;
  }
}

class _AdminSidebar extends StatelessWidget {
  const _AdminSidebar({
    required this.modules,
    required this.currentPath,
    required this.companyName,
    required this.sessionName,
    required this.roleLabel,
    required this.strings,
    required this.onSignOut,
  });

  final List<AdminModule> modules;
  final String currentPath;
  final String companyName;
  final String sessionName;
  final String roleLabel;
  final AdminStrings strings;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
            child: Row(
              children: [
                const AppBrandMark(size: 36),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        companyName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(strings.admin, style: AppTypography.labelMedium.copyWith(color: AppColors.textMuted)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: [
                for (final module in modules)
                  _NavTile(
                    module: module,
                    label: strings.module(module),
                    selected: currentPath == module.path || currentPath.startsWith('${module.path}/'),
                    onTap: () {
                      Navigator.of(context).maybePop();
                      context.go(module.path);
                    },
                  ),
              ],
            ),
          ),
          const Divider(color: AppColors.border, height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(sessionName, style: AppTypography.titleMedium),
                const SizedBox(height: 2),
                Text(roleLabel, style: AppTypography.labelMedium),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
            child: TextButton.icon(
              onPressed: onSignOut,
              icon: const Icon(Icons.logout, size: 18),
              label: Text(strings.signOut),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.module,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final AdminModule module;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: selected ? AppColors.primaryMuted : Colors.transparent,
        borderRadius: AppRadii.mdAll,
        child: InkWell(
          key: Key('admin-nav-${module.name}'),
          onTap: onTap,
          borderRadius: AppRadii.mdAll,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Icon(module.icon, size: 20, color: selected ? AppColors.primary : AppColors.textSecondary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      style: AppTypography.bodyMedium.copyWith(
                        color: selected ? AppColors.textPrimary : AppColors.textSecondary,
                        fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
