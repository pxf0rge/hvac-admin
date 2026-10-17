import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hvac_admin/core/controllers/customer_controller.dart';
import 'package:hvac_admin/core/controllers/gps_map_controller.dart';
import 'package:hvac_admin/core/controllers/job_controller.dart';
import 'package:hvac_admin/core/controllers/settings_controller.dart';
import 'package:hvac_admin/core/controllers/technician_controller.dart';
import 'package:hvac_admin/core/enums/admin_module.dart';
import 'package:hvac_admin/core/enums/domain_enums.dart';
import 'package:hvac_admin/core/maps/address_geocoder.dart';
import 'package:hvac_admin/core/maps/map_coordinates.dart';
import 'package:hvac_admin/core/tracking/job_map_builder.dart';
import 'package:hvac_admin/core/tracking/technician_location_fix.dart';
import 'package:hvac_admin/core/tracking/technician_map_builder.dart';
import 'package:hvac_admin/core/tracking/tracking_policy.dart';
import 'package:hvac_admin/core/utils/formatters.dart';
import 'package:hvac_admin/design_system/design_system.dart';
import 'package:hvac_admin/features/shared/widgets/mobile_list_tile.dart';
import 'package:hvac_admin/features/shared/widgets/osm_map_view.dart';
import 'package:hvac_admin/features/technicians/technician_widgets.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

enum _GpsView { map, list }

enum _MapLayer { both, techs, jobs }

class GpsMapPage extends StatefulWidget {
  const GpsMapPage({super.key});

  @override
  State<GpsMapPage> createState() => _GpsMapPageState();
}

class _GpsMapPageState extends State<GpsMapPage> {
  _GpsView _view = _GpsView.map;
  _MapLayer _layer = _MapLayer.both;
  String? _selectedTechId;
  String? _selectedJobId;
  String? _techFilterId;
  bool _includeOffDuty = false;
  final Map<String, LatLng> _geocodedByPropertyId = {};
  final Set<String> _geocodeInFlight = {};

  TrackingPolicy _policyFor(SettingsController settings) =>
      TrackingPolicy.fromCompanySettings(settings.company);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<TechnicianController>().load();
      context.read<CustomerController>().load();
      context.read<JobController>().loadDispatch();
    });
  }

  List<TechnicianMapSnapshot> _techSnapshots(
    TechnicianController technicians,
    JobController jobs,
    CustomerController directory,
    TrackingPolicy policy,
  ) {
    var snapshots = TechnicianMapBuilder.build(
      technicians: technicians.technicians,
      statusFor: (tech) => jobs.technicians.isNotEmpty ? jobs.boardStatusFor(tech) : tech.status,
      jobsFor: jobs.jobsForTechnician,
      propertyFor: directory.propertyById,
      customerFor: directory.customerById,
      policy: policy,
      includeOffDuty: _includeOffDuty,
    );
    if (_techFilterId != null) {
      snapshots = [for (final item in snapshots) if (item.technician.id == _techFilterId) item];
    }
    return [for (final item in snapshots) if (item.isVisible) item];
  }

  List<JobMapPin> _jobPins(JobController jobs, CustomerController directory, TechnicianController technicians) {
    var pins = JobMapBuilder.buildForDay(
      jobs: jobs.jobs,
      propertyFor: directory.propertyById,
      customerFor: directory.customerById,
      technicianFor: technicians.technicianById,
      geocodedByPropertyId: _geocodedByPropertyId,
    );
    if (_techFilterId != null) {
      pins = [for (final pin in pins) if (pin.job.technicianId == _techFilterId) pin];
    }
    return pins;
  }

  void _scheduleGeocode(List<JobMapPin> pins) {
    for (final pin in pins) {
      if (!pin.needsGeocode) continue;
      final propertyId = pin.property?.id;
      if (propertyId == null || propertyId.isEmpty) continue;
      if (_geocodedByPropertyId.containsKey(propertyId)) continue;
      if (_geocodeInFlight.contains(propertyId)) continue;
      _geocodeInFlight.add(propertyId);
      final query = pin.geocodeQuery;
      () async {
        try {
          final point = await AddressGeocoder.lookup(query);
          if (!mounted) return;
          setState(() {
            _geocodeInFlight.remove(propertyId);
            if (point != null) _geocodedByPropertyId[propertyId] = point;
          });
        } catch (_) {
          if (!mounted) return;
          setState(() => _geocodeInFlight.remove(propertyId));
        }
      }();
    }
  }

  void _onMarkerTap(String id) {
    if (id.startsWith('job:')) {
      final jobId = id.substring(4);
      setState(() {
        _selectedJobId = jobId;
        // Focus related tech when assigned.
        final jobs = context.read<JobController>();
        final job = jobs.jobById(jobId);
        if (job?.technicianId != null && job!.technicianId!.isNotEmpty) {
          _selectedTechId = job.technicianId;
        }
      });
      return;
    }
    setState(() => _selectedTechId = id);
    context.read<GpsMapController>().loadHistory(id);
  }

  @override
  Widget build(BuildContext context) {
    final technicians = context.watch<TechnicianController>();
    final jobs = context.watch<JobController>();
    final directory = context.watch<CustomerController>();
    final gps = context.watch<GpsMapController>();
    final settings = context.watch<SettingsController>();
    final policy = _policyFor(settings);

    if (technicians.isLoading && technicians.technicians.isEmpty) {
      return const LoadingState(message: 'Loading map…');
    }

    final techSnapshots = _techSnapshots(technicians, jobs, directory, policy);
    final jobPins = _jobPins(jobs, directory, technicians);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scheduleGeocode(jobPins));

    final showTechs = _layer == _MapLayer.both || _layer == _MapLayer.techs;
    final showJobs = _layer == _MapLayer.both || _layer == _MapLayer.jobs;

    TechnicianMapSnapshot? selectedTech;
    if (showTechs) {
      for (final item in techSnapshots) {
        if (item.technician.id == _selectedTechId) {
          selectedTech = item;
          break;
        }
      }
      if (selectedTech == null && _selectedTechId == null && techSnapshots.isNotEmpty && _selectedJobId == null) {
        selectedTech = techSnapshots.first;
      }
    }

    JobMapPin? selectedJob;
    if (showJobs && _selectedJobId != null) {
      for (final pin in jobPins) {
        if (pin.job.id == _selectedJobId) {
          selectedJob = pin;
          break;
        }
      }
    }

    final hasContent =
        (showTechs && techSnapshots.isNotEmpty) || (showJobs && jobPins.isNotEmpty);

    return Padding(
      key: const Key('gps-map-page'),
      padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Dispatch map', style: AppTypography.headlineMedium),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Technicians and today’s open jobs. GPS gated to working hours (${policy.hoursLabel}).',
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ),
              ),
              AppSecondaryButton(
                label: 'Directory',
                icon: Icons.list_alt_outlined,
                onPressed: () => context.go(AdminModule.technicians.path),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SegmentedButton<_GpsView>(
                segments: const [
                  ButtonSegment(value: _GpsView.map, label: Text('Map'), icon: Icon(Icons.map_outlined)),
                  ButtonSegment(value: _GpsView.list, label: Text('List'), icon: Icon(Icons.view_list_outlined)),
                ],
                selected: {_view},
                onSelectionChanged: (value) => setState(() => _view = value.first),
              ),
              SegmentedButton<_MapLayer>(
                key: const Key('map-layer-toggle'),
                segments: const [
                  ButtonSegment(value: _MapLayer.both, label: Text('Both')),
                  ButtonSegment(value: _MapLayer.techs, label: Text('Techs')),
                  ButtonSegment(value: _MapLayer.jobs, label: Text('Jobs')),
                ],
                selected: {_layer},
                onSelectionChanged: (value) => setState(() => _layer = value.first),
              ),
              FilterChip(
                label: const Text('Show off duty'),
                selected: _includeOffDuty,
                onSelected: (value) => setState(() => _includeOffDuty = value),
              ),
              DropdownButton<String?>(
                key: const Key('map-tech-filter'),
                value: _techFilterId,
                hint: const Text('All technicians'),
                items: [
                  const DropdownMenuItem<String?>(value: null, child: Text('All technicians')),
                  for (final tech in technicians.technicians)
                    DropdownMenuItem(value: tech.id, child: Text(tech.displayName)),
                ],
                onChanged: (value) => setState(() => _techFilterId = value),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: !hasContent
                ? const EmptyState(
                    key: Key('gps-map-empty'),
                    title: 'Nothing on the map',
                    message: 'No visible technicians or open jobs for today with the current filters.',
                    icon: Icons.location_off_outlined,
                  )
                : _view == _GpsView.map
                    ? _MapLayout(
                        techSnapshots: showTechs ? techSnapshots : const [],
                        jobPins: showJobs ? jobPins : const [],
                        selectedTechId: selectedTech?.technician.id,
                        selectedJobId: selectedJob?.job.id,
                        onMarkerTap: _onMarkerTap,
                        selectedTech: selectedTech,
                        selectedJob: selectedJob,
                        gps: gps,
                      )
                    : _ListLayout(
                        techSnapshots: showTechs ? techSnapshots : const [],
                        jobPins: showJobs ? jobPins : const [],
                        onSelectTech: (id) {
                          setState(() => _selectedTechId = id);
                          gps.loadHistory(id);
                        },
                        onSelectJob: (id) => setState(() => _selectedJobId = id),
                        selectedTech: selectedTech,
                        selectedJob: selectedJob,
                        gps: gps,
                      ),
          ),
        ],
      ),
    );
  }
}

class _MapLayout extends StatelessWidget {
  const _MapLayout({
    required this.techSnapshots,
    required this.jobPins,
    required this.selectedTechId,
    required this.selectedJobId,
    required this.onMarkerTap,
    required this.selectedTech,
    required this.selectedJob,
    required this.gps,
  });

  final List<TechnicianMapSnapshot> techSnapshots;
  final List<JobMapPin> jobPins;
  final String? selectedTechId;
  final String? selectedJobId;
  final ValueChanged<String> onMarkerTap;
  final TechnicianMapSnapshot? selectedTech;
  final JobMapPin? selectedJob;
  final GpsMapController gps;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= AppBreakpoints.mobile;
    final map = _TrackingMap(
      techSnapshots: techSnapshots,
      jobPins: jobPins,
      selectedTechId: selectedTechId,
      selectedJobId: selectedJobId,
      onMarkerTap: onMarkerTap,
    );

    final Widget details;
    if (wide && selectedJob != null && selectedTech != null && selectedJobId != null) {
      details = ListView(
        children: [
          _JobMapPanel(pin: selectedJob!),
          const SizedBox(height: AppSpacing.md),
          _TechnicianMapPanel(snapshot: selectedTech!, history: gps.historyFor(selectedTech!.technician.id)),
        ],
      );
    } else if (selectedJob != null) {
      details = _JobMapPanel(pin: selectedJob!);
    } else if (selectedTech != null) {
      details = _TechnicianMapPanel(snapshot: selectedTech!, history: gps.historyFor(selectedTech!.technician.id));
    } else {
      details = const EmptyState(title: 'Select a technician or job', icon: Icons.touch_app_outlined);
    }

    if (wide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: 3, child: map),
          const SizedBox(width: AppSpacing.md),
          SizedBox(width: 340, child: details),
        ],
      );
    }

    return Column(
      children: [
        Expanded(flex: 3, child: map),
        const SizedBox(height: AppSpacing.md),
        Expanded(flex: 2, child: details),
      ],
    );
  }
}

class _ListLayout extends StatelessWidget {
  const _ListLayout({
    required this.techSnapshots,
    required this.jobPins,
    required this.onSelectTech,
    required this.onSelectJob,
    required this.selectedTech,
    required this.selectedJob,
    required this.gps,
  });

  final List<TechnicianMapSnapshot> techSnapshots;
  final List<JobMapPin> jobPins;
  final ValueChanged<String> onSelectTech;
  final ValueChanged<String> onSelectJob;
  final TechnicianMapSnapshot? selectedTech;
  final JobMapPin? selectedJob;
  final GpsMapController gps;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            key: const Key('gps-list-view'),
            children: [
              if (techSnapshots.isNotEmpty) ...[
                const Text('Technicians', style: AppTypography.titleMedium),
                const SizedBox(height: AppSpacing.sm),
                for (final snapshot in techSnapshots) ...[
                  MobileListTile(
                    key: Key('gps-list-${snapshot.technician.id}'),
                    title: snapshot.headline,
                    subtitle: snapshot.customerName ?? '',
                    meta: snapshot.isStale
                        ? 'Stale location'
                        : 'Updated ${formatDateTime(snapshot.technician.lastUpdated)}',
                    trailing: TechnicianStatusChip(status: snapshot.status),
                    onTap: () => onSelectTech(snapshot.technician.id),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
              ],
              if (jobPins.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                const Text("Today's jobs", style: AppTypography.titleMedium),
                const SizedBox(height: AppSpacing.sm),
                for (final pin in jobPins) ...[
                  MobileListTile(
                    key: Key('gps-list-job-${pin.job.id}'),
                    title: pin.headline,
                    subtitle: pin.technician?.displayName ?? 'Unassigned',
                    meta: pin.point == null ? 'No coordinates yet' : 'On map',
                    trailing: StatusChip(
                      label: pin.job.status.label,
                      background: AppColors.warningMuted,
                      foreground: AppColors.warning,
                    ),
                    onTap: () => onSelectJob(pin.job.id),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
              ],
            ],
          ),
        ),
        if (selectedJob != null || selectedTech != null) ...[
          const SizedBox(width: AppSpacing.md),
          SizedBox(
            width: 340,
            child: selectedJob != null
                ? _JobMapPanel(pin: selectedJob!)
                : _TechnicianMapPanel(
                    snapshot: selectedTech!,
                    history: gps.historyFor(selectedTech!.technician.id),
                  ),
          ),
        ],
      ],
    );
  }
}

class _TrackingMap extends StatelessWidget {
  const _TrackingMap({
    required this.techSnapshots,
    required this.jobPins,
    required this.selectedTechId,
    required this.selectedJobId,
    required this.onMarkerTap,
  });

  final List<TechnicianMapSnapshot> techSnapshots;
  final List<JobMapPin> jobPins;
  final String? selectedTechId;
  final String? selectedJobId;
  final ValueChanged<String> onMarkerTap;

  @override
  Widget build(BuildContext context) {
    final markers = <OsmMapMarker>[];

    for (final snapshot in techSnapshots) {
      final tech = snapshot.technician;
      final point = MapCoordinates.fromNullable(tech.latitude, tech.longitude);
      if (point == null) continue;
      final colors = technicianStatusColors(snapshot.status);
      final color = snapshot.isStale ? AppColors.warning : colors.$2;
      markers.add(
        OsmMapMarker(
          id: tech.id,
          point: point,
          title: tech.displayName,
          subtitle: snapshot.status.label,
          color: color,
          selected: tech.id == selectedTechId,
          stale: snapshot.isStale,
          icon: Icons.person_pin_circle,
        ),
      );
    }

    for (final pin in jobPins) {
      final point = pin.point;
      if (point == null) continue;
      markers.add(
        OsmMapMarker(
          id: pin.markerId,
          point: point,
          title: pin.job.jobNumber,
          subtitle: pin.job.type.label,
          color: AppColors.warning,
          selected: pin.job.id == selectedJobId,
          icon: Icons.home_work_outlined,
          isJob: true,
        ),
      );
    }

    final linkLines = <(LatLng, LatLng)>[];
    if (selectedJobId != null && selectedTechId != null) {
      JobMapPin? job;
      for (final pin in jobPins) {
        if (pin.job.id == selectedJobId) {
          job = pin;
          break;
        }
      }
      TechnicianMapSnapshot? tech;
      for (final snapshot in techSnapshots) {
        if (snapshot.technician.id == selectedTechId) {
          tech = snapshot;
          break;
        }
      }
      final jobPoint = job?.point;
      final techPoint = tech == null
          ? null
          : MapCoordinates.fromNullable(tech.technician.latitude, tech.technician.longitude);
      if (jobPoint != null && techPoint != null) {
        linkLines.add((techPoint, jobPoint));
      }
    }

    final selectedMarkerId =
        selectedJobId != null ? 'job:$selectedJobId' : selectedTechId;

    return SurfaceCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: AppRadii.lgAll,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  const StatusChip(
                    label: 'Technician',
                    background: AppColors.primaryMuted,
                    foreground: AppColors.primary,
                  ),
                  const StatusChip(
                    label: 'Job address',
                    background: AppColors.warningMuted,
                    foreground: AppColors.warning,
                  ),
                  Text(
                    '${techSnapshots.length} techs · ${jobPins.where((p) => p.point != null).length}/${jobPins.length} jobs on map',
                    style: AppTypography.labelSmall,
                  ),
                ],
              ),
            ),
            Expanded(
              child: markers.isEmpty
                  ? const Center(
                      child: Text(
                        'No coordinates yet for visible technicians or jobs.',
                        style: AppTypography.bodySmall,
                      ),
                    )
                  : OsmMapView(
                      mapKey: const Key('technician-map'),
                      markers: markers,
                      selectedId: selectedMarkerId,
                      onMarkerTap: onMarkerTap,
                      linkLines: linkLines,
                      footer: 'Live GPS + today’s jobs · OpenStreetMap',
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TechnicianMapPanel extends StatelessWidget {
  const _TechnicianMapPanel({required this.snapshot, required this.history});

  final TechnicianMapSnapshot snapshot;
  final List<TechnicianLocationFix> history;

  @override
  Widget build(BuildContext context) {
    final tech = snapshot.technician;
    final job = snapshot.currentJob;

    return SurfaceCard(
      child: SingleChildScrollView(
        key: const Key('technician-map-panel'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(tech.displayName, style: AppTypography.headlineMedium)),
                TechnicianStatusChip(status: snapshot.status),
              ],
            ),
            const SizedBox(height: 6),
            Text(snapshot.jobAddress ?? tech.lastAddress, style: AppTypography.bodySmall),
            Text(
              snapshot.isStale
                  ? 'Last update stale — ${formatDateTime(tech.lastUpdated)}'
                  : 'Updated ${formatDateTime(tech.lastUpdated)}',
              style: AppTypography.labelSmall.copyWith(
                color: snapshot.isStale ? AppColors.warning : AppColors.textMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                AppSecondaryButton(
                  label: 'Open technician',
                  onPressed: () => context.go('${AdminModule.technicians.path}/${tech.id}'),
                ),
                if (job != null)
                  AppSecondaryButton(
                    label: 'Open job',
                    onPressed: () => context.go('${AdminModule.jobs.path}/${job.id}'),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            const SectionHeader(title: 'Current job'),
            if (job == null)
              const Text('No open job.', style: AppTypography.bodySmall)
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(job.jobNumber, style: AppTypography.titleMedium),
                  Text(job.type.label, style: AppTypography.bodySmall),
                  if (snapshot.customerName != null) Text(snapshot.customerName!, style: AppTypography.bodyMedium),
                  Text(
                    '${formatRelativeDate(job.date)}  ·  ${formatTimeRange(job.startTime, job.endTime)}',
                    style: AppTypography.labelSmall,
                  ),
                ],
              ),
            const SizedBox(height: AppSpacing.lg),
            const SectionHeader(title: 'Recent GPS fixes'),
            if (history.isEmpty)
              const Text('No location history yet.', style: AppTypography.bodySmall)
            else
              for (final fix in history.take(6))
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Text(
                    '${formatDateTime(fix.recordedAt.toIso8601String())}'
                    '${fix.lastAddress != null && fix.lastAddress!.isNotEmpty ? '  ·  ${fix.lastAddress}' : ''}',
                    style: AppTypography.bodySmall,
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _JobMapPanel extends StatelessWidget {
  const _JobMapPanel({required this.pin});

  final JobMapPin pin;

  @override
  Widget build(BuildContext context) {
    final job = pin.job;
    return SurfaceCard(
      child: SingleChildScrollView(
        key: const Key('job-map-panel'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(job.jobNumber, style: AppTypography.headlineMedium)),
                StatusChip(
                  label: job.status.label,
                  background: AppColors.warningMuted,
                  foreground: AppColors.warning,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(job.type.label, style: AppTypography.bodyMedium),
            Text(pin.addressLabel, style: AppTypography.bodySmall),
            if (pin.customer != null)
              Text(pin.customer!.displayName, style: AppTypography.bodyMedium),
            Text(
              '${formatRelativeDate(job.date)}  ·  ${formatTimeRange(job.startTime, job.endTime)}',
              style: AppTypography.labelSmall,
            ),
            if (pin.point == null)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Text(
                  pin.needsGeocode ? 'Resolving map coordinates…' : 'No coordinates for this property yet.',
                  style: AppTypography.labelSmall.copyWith(color: AppColors.warning),
                ),
              ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                AppSecondaryButton(
                  label: 'Open job',
                  onPressed: () => context.go('${AdminModule.jobs.path}/${job.id}'),
                ),
                if (pin.technician != null)
                  AppSecondaryButton(
                    label: 'Open technician',
                    onPressed: () => context.go('${AdminModule.technicians.path}/${pin.technician!.id}'),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            const SectionHeader(title: 'Assigned technician'),
            Text(
              pin.technician?.displayName ?? 'Unassigned',
              style: AppTypography.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
