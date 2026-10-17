import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';

import 'package:hvac_admin/core/controllers/dashboard_controller.dart';

import 'package:hvac_admin/core/controllers/maintenance_agreement_controller.dart';

import 'package:hvac_admin/core/controllers/management_auth_controller.dart';

import 'package:hvac_admin/core/enums/admin_module.dart';

import 'package:hvac_admin/core/models/dashboard_snapshot.dart';

import 'package:hvac_admin/core/utils/formatters.dart';
import 'package:hvac_admin/design_system/design_system.dart';
import 'package:hvac_admin/features/shared/widgets/language_toggle.dart';
import 'package:provider/provider.dart';



class DashboardPage extends StatefulWidget {

  const DashboardPage({super.key});



  @override

  State<DashboardPage> createState() => _DashboardPageState();

}



class _DashboardPageState extends State<DashboardPage> {

  @override

  void initState() {

    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) => _loadDashboard());

  }



  void _loadDashboard({bool force = false}) {

    if (!mounted) return;

    final auth = context.read<ManagementAuthController>();

    context.read<DashboardController>().load(

          includeFinancial: auth.canViewFinancials,

          force: force,

        );

    context.read<MaintenanceAgreementController>().load(force: force);

  }



  @override

  Widget build(BuildContext context) {

    final auth = context.watch<ManagementAuthController>();

    final dashboard = context.watch<DashboardController>();

    final maintenance = context.watch<MaintenanceAgreementController>();

    final session = auth.session;

    final snap = dashboard.snapshot;

    final canViewFinancials = auth.canViewFinancials;

    final expiringAgreements = maintenance.agreementsFor(expiringOnly: true);
    final strings = adminStrings(context);

    if (dashboard.isLoading && !dashboard.hasData) {
      return LoadingState(message: strings.loadingDashboard);
    }



    if (dashboard.error != null && !dashboard.hasData) {

      return ErrorState(message: dashboard.error!, onRetry: () => _loadDashboard(force: true));

    }



    return SingleChildScrollView(

      key: const Key('dashboard'),

      restorationId: 'dashboard-scroll',

      padding: const EdgeInsets.all(AppSpacing.xl),

      child: Column(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          Text(

            'Welcome back${session != null ? ', ${session.firstName}' : ''}',

            style: AppTypography.headlineMedium,

          ),

          const SizedBox(height: AppSpacing.xs),

          if (session != null)

            Text('Signed in as ${session.role.name}', style: AppTypography.bodySmall),

          const SizedBox(height: AppSpacing.xl),

          const SectionHeader(title: 'Quick actions'),

          Wrap(

            spacing: AppSpacing.sm,

            runSpacing: AppSpacing.sm,

            children: [

              AppSecondaryButton(

                label: 'Create job',

                onPressed: () => context.go(AdminModule.jobs.path),

              ),

              AppSecondaryButton(

                label: 'Open dispatch',

                onPressed: () => context.go(AdminModule.dispatch.path),

              ),

              AppSecondaryButton(

                label: 'View calendar',

                onPressed: () => context.go(AdminModule.calendar.path),

              ),

            ],

          ),

          if (expiringAgreements.isNotEmpty) ...[

            const SizedBox(height: AppSpacing.xl),

            SurfaceCard(

              key: const Key('dashboard-expiring-maintenance'),

              child: Row(

                children: [

                  const Icon(Icons.assignment_late_outlined, color: AppColors.warning),

                  const SizedBox(width: AppSpacing.md),

                  Expanded(

                    child: Text(

                      '${expiringAgreements.length} maintenance agreement${expiringAgreements.length == 1 ? '' : 's'} need renewal within 30 days.',

                      style: AppTypography.bodyMedium,

                    ),

                  ),

                  AppSecondaryButton(

                    label: 'Review',

                    onPressed: () => context.go(AdminModule.maintenanceAgreements.path),

                  ),

                ],

              ),

            ),

          ],

          const SizedBox(height: AppSpacing.xl),

          const SectionHeader(title: 'Operations'),

          if (!snap.hasOperationalData)

            const SurfaceCard(

              child: Text(

                'No jobs or technicians yet. Operational KPIs appear after dispatch data is loaded.',

                style: AppTypography.bodySmall,

              ),

            )

          else

            ResponsiveBuilder(

              mobile: _KpiGrid(columns: 1, children: _operationalKpis(snap)),

              tablet: _KpiGrid(columns: 2, children: _operationalKpis(snap)),

              desktop: _KpiGrid(columns: 4, children: _operationalKpis(snap)),

            ),

          const SizedBox(height: AppSpacing.xl),

          if (canViewFinancials) ...[

            const SectionHeader(title: 'Financial'),

            if (!snap.hasFinancialData)

              const SurfaceCard(

                child: Text(

                  'No billing data yet. Financial KPIs appear after estimates and invoices are populated.',

                  style: AppTypography.bodySmall,

                ),

              )

            else

              KeyedSubtree(

                key: const Key('dashboard-financial'),

                child: ResponsiveBuilder(

                  mobile: _KpiGrid(columns: 1, children: _financialKpis(snap)),

                  tablet: _KpiGrid(columns: 2, children: _financialKpis(snap)),

                  desktop: _KpiGrid(columns: 2, children: _financialKpis(snap)),

                ),

              ),

          ] else

            const SurfaceCard(

              child: Text(

                'Financial metrics are hidden for this role.',

                style: AppTypography.bodySmall,

              ),

            ),

          const SizedBox(height: AppSpacing.xl),

          const SectionHeader(title: 'Recent activity'),

          SurfaceCard(

            child: snap.recentActivity.isEmpty

                ? const Text('No recent activity yet.', style: AppTypography.bodyMedium)

                : Column(

                    children: [

                      for (var i = 0; i < snap.recentActivity.length; i++) ...[

                        if (i > 0) const Divider(height: AppSpacing.xl),

                        _ActivityRow(item: snap.recentActivity[i]),

                      ],

                    ],

                  ),

          ),

          if (canViewFinancials) ...[

            const SizedBox(height: AppSpacing.lg),

            AppTextAction(

              label: 'View reports',

              onPressed: () => context.go(AdminModule.reports.path),

            ),

          ],

        ],

      ),

    );

  }



  List<Widget> _operationalKpis(DashboardSnapshot snap) {

    return [

      KpiCard(

        key: const Key('dashboard-todays-jobs'),

        label: "Today's jobs",

        value: '${snap.todaysJobs}',

        icon: Icons.today_outlined,

      ),

      KpiCard(

        key: const Key('dashboard-unassigned'),

        label: 'Unassigned',

        value: '${snap.unassignedJobs}',

        icon: Icons.pending_actions_outlined,

        valueColor: snap.unassignedJobs > 0 ? AppColors.warning : null,

      ),

      KpiCard(

        key: const Key('dashboard-active-techs'),

        label: 'Active technicians',

        value: '${snap.activeTechnicians}',

        icon: Icons.engineering_outlined,

      ),

      KpiCard(

        key: const Key('dashboard-jobs-completed'),

        label: 'Jobs completed',

        value: '${snap.jobsCompleted}',

        subtitle: '${snap.jobsOpen} open · ${snap.jobsTotal} total',

        icon: Icons.task_alt_outlined,

        valueColor: AppColors.success,

      ),

    ];

  }



  List<Widget> _financialKpis(DashboardSnapshot snap) {

    return [

      KpiCard(

        key: const Key('dashboard-open-estimates'),

        label: 'Open estimates',

        value: '${snap.openEstimates}',

        subtitle: 'Draft or sent',

        icon: Icons.request_quote_outlined,

      ),

      KpiCard(

        key: const Key('dashboard-overdue-invoices'),

        label: 'Overdue invoices',

        value: '${snap.overdueInvoiceCount}',

        subtitle: formatCurrency(snap.overdueInvoiceTotal),

        icon: Icons.warning_amber_outlined,

        valueColor: snap.overdueInvoiceCount > 0 ? AppColors.danger : null,

      ),

    ];

  }

}



class _KpiGrid extends StatelessWidget {

  const _KpiGrid({required this.children, required this.columns});



  final List<Widget> children;

  final int columns;



  @override

  Widget build(BuildContext context) {

    return LayoutBuilder(

      builder: (context, constraints) {

        final width = (constraints.maxWidth - (columns - 1) * AppSpacing.md) / columns;

        return Wrap(

          spacing: AppSpacing.md,

          runSpacing: AppSpacing.md,

          children: [

            for (final child in children)

              SizedBox(width: width.clamp(180, constraints.maxWidth), child: child),

          ],

        );

      },

    );

  }

}



class _ActivityRow extends StatelessWidget {

  const _ActivityRow({required this.item});



  final DashboardActivityItem item;



  @override

  Widget build(BuildContext context) {

    return Row(

      crossAxisAlignment: CrossAxisAlignment.start,

      children: [

        Expanded(

          child: Column(

            crossAxisAlignment: CrossAxisAlignment.start,

            children: [

              Text(item.title, style: AppTypography.titleMedium),

              const SizedBox(height: AppSpacing.xs),

              Text(item.detail, style: AppTypography.bodySmall),

            ],

          ),

        ),

        const SizedBox(width: AppSpacing.md),

        Text(item.at, style: AppTypography.labelMedium.copyWith(color: AppColors.textMuted)),

      ],

    );

  }

}


