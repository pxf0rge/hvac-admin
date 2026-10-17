import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:hvac_admin/core/maps/map_coordinates.dart';
import 'package:hvac_admin/design_system/design_system.dart';
import 'package:latlong2/latlong.dart';

class OsmMapMarker {
  const OsmMapMarker({
    required this.id,
    required this.point,
    required this.title,
    required this.subtitle,
    required this.color,
    this.selected = false,
    this.stale = false,
    this.icon = Icons.person_pin_circle,
    this.isJob = false,
  });

  final String id;
  final LatLng point;
  final String title;
  final String subtitle;
  final Color color;
  final bool selected;
  final bool stale;
  final IconData icon;
  final bool isJob;
}

class OsmMapView extends StatefulWidget {
  const OsmMapView({
    super.key,
    required this.markers,
    this.mapKey,
    this.selectedId,
    this.onMarkerTap,
    this.footer,
    this.initialZoom = 13,
    this.linkLines = const [],
  });

  final List<OsmMapMarker> markers;
  final Key? mapKey;
  final String? selectedId;
  final ValueChanged<String>? onMarkerTap;
  final String? footer;
  final double initialZoom;

  /// Optional tech↔job connection segments.
  final List<(LatLng, LatLng)> linkLines;

  @override
  State<OsmMapView> createState() => _OsmMapViewState();
}

class _OsmMapViewState extends State<OsmMapView> {
  final MapController _controller = MapController();
  List<LatLng> _lastFitted = const [];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant OsmMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) => _fitToMarkers());
  }

  void _fitToMarkers() {
    final points = MapCoordinates.fromPoints(widget.markers.map((marker) => marker.point));
    if (points.isEmpty) return;
    if (_pointsEqual(points, _lastFitted) && widget.selectedId == null) return;

    if (points.length == 1) {
      _controller.move(points.first, widget.initialZoom);
    } else {
      // Degenerate bounds (all markers on the same spot) would produce a
      // non-finite zoom in CameraFit.bounds — fall back to a fixed-zoom move.
      final uniquePoints = points.toSet();
      if (uniquePoints.length == 1) {
        _controller.move(uniquePoints.single, widget.initialZoom);
      } else {
        _controller.fitCamera(
          CameraFit.bounds(
            bounds: LatLngBounds.fromPoints(points),
            padding: const EdgeInsets.all(56),
          ),
        );
      }
    }
    _lastFitted = points;

    final selectedId = widget.selectedId;
    if (selectedId != null) {
      OsmMapMarker? selected;
      for (final marker in widget.markers) {
        if (marker.id == selectedId) {
          selected = marker;
          break;
        }
      }
      if (selected != null) {
        _controller.move(selected.point, _controller.camera.zoom < 12 ? 12 : _controller.camera.zoom);
      }
    }
  }

  bool _pointsEqual(List<LatLng> a, List<LatLng> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].latitude != b[i].latitude || a[i].longitude != b[i].longitude) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final markers = widget.markers;
    final points = MapCoordinates.fromPoints(markers.map((marker) => marker.point));
    final center = points.isEmpty ? const LatLng(39.78, -89.65) : points.first;

    return Stack(
      key: widget.mapKey,
      children: [
        Positioned.fill(
          child: FlutterMap(
            mapController: _controller,
            options: MapOptions(
              initialCenter: center,
              initialZoom: widget.initialZoom,
              onMapReady: _fitToMarkers,
              interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.hvacpro.admin',
              ),
              if (widget.linkLines.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    for (final line in widget.linkLines)
                      Polyline(
                        points: [line.$1, line.$2],
                        color: AppColors.accent.withValues(alpha: 0.75),
                        strokeWidth: 3,
                      ),
                  ],
                ),
              if (markers.isNotEmpty)
                MarkerLayer(
                  markers: [
                    for (final marker in markers)
                      Marker(
                        point: marker.point,
                        width: 140,
                        height: 58,
                        child: GestureDetector(
                          key: Key('map-marker-${marker.id}'),
                          onTap: () => widget.onMarkerTap?.call(marker.id),
                          child: _MarkerChip(marker: marker),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
        const Positioned(
          right: 8,
          bottom: 8,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Color(0xCC111418),
              borderRadius: BorderRadius.all(Radius.circular(6)),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Text('© OpenStreetMap', style: TextStyle(fontSize: 10, color: Colors.white70)),
            ),
          ),
        ),
        if (widget.footer != null)
          Positioned(
            left: 12,
            bottom: 10,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xCC111418),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text(widget.footer!, style: AppTypography.labelSmall.copyWith(color: Colors.white70)),
              ),
            ),
          ),
      ],
    );
  }
}

class _MarkerChip extends StatelessWidget {
  const _MarkerChip({required this.marker});

  final OsmMapMarker marker;

  @override
  Widget build(BuildContext context) {
    final borderColor = marker.stale ? AppColors.warning : marker.color;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: marker.selected ? marker.color.withValues(alpha: 0.18) : AppColors.surface,
        borderRadius: AppRadii.mdAll,
        border: Border.all(color: marker.selected ? borderColor : AppColors.border, width: marker.selected ? 2 : 1),
        boxShadow: const [BoxShadow(color: Color(0x44000000), blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(marker.icon, size: 16, color: borderColor),
          const SizedBox(width: 6),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  marker.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelMedium.copyWith(
                    color: marker.selected ? AppColors.textPrimary : AppColors.textSecondary,
                  ),
                ),
                Text(
                  marker.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelSmall.copyWith(color: borderColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
