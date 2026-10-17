import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:hvac_admin/core/maps/address_geocoder.dart';
import 'package:hvac_admin/core/maps/map_coordinates.dart';
import 'package:hvac_admin/design_system/design_system.dart';
import 'package:latlong2/latlong.dart';

typedef MapAddressChanged = void Function({
  required LatLng point,
  required ResolvedAddress? address,
});

class MapAddressPicker extends StatefulWidget {
  const MapAddressPicker({
    super.key,
    this.initialPoint,
    this.onChanged,
    this.onSearchAddress,
    this.height = 260,
  });

  final LatLng? initialPoint;
  final MapAddressChanged? onChanged;
  final Future<String> Function()? onSearchAddress;
  final double height;

  @override
  State<MapAddressPicker> createState() => MapAddressPickerState();
}

class MapAddressPickerState extends State<MapAddressPicker> {
  final MapController _controller = MapController();
  LatLng? _point;
  bool _resolving = false;
  String? _status;

  @override
  void initState() {
    super.initState();
    _point = widget.initialPoint;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final point = _point;
      if (point != null) {
        _controller.move(point, 16);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> searchFromQuery(String query) => _searchCurrentAddress(query);

  Future<void> _selectPoint(LatLng point) async {
    setState(() {
      _point = point;
      _resolving = true;
      _status = 'Looking up address…';
    });
    ResolvedAddress? resolved;
    try {
      resolved = await AddressGeocoder.reverse(point);
    } catch (_) {
      resolved = null;
    }
    if (!mounted) return;
    setState(() {
      _resolving = false;
      _status = resolved == null
          ? 'Could not resolve address. You can still edit fields manually.'
          : resolved.displayName;
    });
    widget.onChanged?.call(point: point, address: resolved);
  }

  Future<void> _searchCurrentAddress(String query) async {
    if (query.trim().isEmpty) return;
    setState(() {
      _resolving = true;
      _status = 'Searching map…';
    });
    try {
      final point = await AddressGeocoder.lookup(query);
      if (!mounted) return;
      if (point == null) {
        setState(() {
          _resolving = false;
          _status = 'Address not found on map. Tap the map to place a pin.';
        });
        return;
      }
      _controller.move(point, 16);
      await _selectPoint(point);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _resolving = false;
        _status = 'Search failed. Tap the map to place a pin.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final point = _point;
    final center = point ?? widget.initialPoint ?? const LatLng(39.7817, -89.6501);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Tap the map to set the property pin.',
                style: AppTypography.bodySmall,
              ),
            ),
            AppSecondaryButton(
              label: 'Use typed address',
              onPressed: _resolving || widget.onSearchAddress == null
                  ? null
                  : () async {
                      final query = await widget.onSearchAddress!();
                      if (!mounted) return;
                      await _searchCurrentAddress(query);
                    },
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        ClipRRect(
          borderRadius: AppRadii.lgAll,
          child: SizedBox(
            height: widget.height,
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _controller,
                  options: MapOptions(
                    initialCenter: center,
                    initialZoom: point == null ? 4 : 16,
                    onTap: (_, tapPoint) => _selectPoint(tapPoint),
                    interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.hvacpro.admin',
                    ),
                    if (point != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: point,
                            width: 36,
                            height: 36,
                            child: const Icon(Icons.location_on, color: AppColors.primary, size: 34),
                          ),
                        ],
                      ),
                  ],
                ),
                if (_resolving)
                  const Positioned.fill(
                    child: ColoredBox(
                      color: Color(0x66000000),
                      child: Center(child: CircularProgressIndicator()),
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
              ],
            ),
          ),
        ),
        if (_status != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(_status!, style: AppTypography.labelSmall),
        ],
        if (point != null && MapCoordinates.isValid(point.latitude, point.longitude)) ...[
          const SizedBox(height: 4),
          Text(
            '${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}',
            style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted),
          ),
        ],
      ],
    );
  }
}
