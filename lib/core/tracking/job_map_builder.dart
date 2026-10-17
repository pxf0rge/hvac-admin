import 'package:hvac_admin/core/models/office_directory.dart';
import 'package:hvac_admin/core/enums/domain_enums.dart';
import 'package:hvac_admin/core/utils/formatters.dart';
import 'package:latlong2/latlong.dart';

/// Open job pin for the dispatch/GPS map (today's schedule).
class JobMapPin {
  const JobMapPin({
    required this.job,
    required this.addressLabel,
    this.property,
    this.customer,
    this.technician,
    this.point,
    this.needsGeocode = false,
    this.geocodeQuery = '',
  });

  final HistoryJob job;
  final String addressLabel;
  final OfficeProperty? property;
  final OfficeCustomer? customer;
  final OfficeTechnician? technician;
  final LatLng? point;
  final bool needsGeocode;
  final String geocodeQuery;

  String get markerId => 'job:${job.id}';

  String get headline {
    final parts = <String>[job.jobNumber, job.type.label];
    if (addressLabel.isNotEmpty) parts.add(addressLabel);
    return parts.join(' — ');
  }
}

abstract final class JobMapBuilder {
  /// Open jobs scheduled for [day] (defaults to local today).
  static List<JobMapPin> buildForDay({
    required List<HistoryJob> jobs,
    required OfficeProperty? Function(String propertyId) propertyFor,
    required OfficeCustomer? Function(String customerId) customerFor,
    required OfficeTechnician? Function(String technicianId) technicianFor,
    DateTime? day,
    Map<String, LatLng> geocodedByPropertyId = const {},
  }) {
    final date = isoDate(day ?? DateTime.now());
    final pins = <JobMapPin>[];

    for (final job in jobs) {
      if (!job.isOpen) continue;
      if (job.date != date) continue;

      final property = propertyFor(job.propertyId);
      final customer = property == null ? null : customerFor(property.customerId);
      final technician =
          job.technicianId == null || job.technicianId!.isEmpty ? null : technicianFor(job.technicianId!);

      LatLng? point;
      var needsGeocode = false;
      var geocodeQuery = '';

      if (property != null) {
        final lat = property.latitude;
        final lng = property.longitude;
        if (lat != null && lng != null && lat.abs() > 0.01 && lng.abs() > 0.01) {
          point = LatLng(lat, lng);
        } else {
          final cached = geocodedByPropertyId[property.id];
          if (cached != null) {
            point = cached;
          } else {
            needsGeocode = true;
            geocodeQuery = [
              property.address,
              property.city,
              property.state,
              property.zip,
            ].where((part) => part.trim().isNotEmpty).join(', ');
          }
        }
      }

      pins.add(
        JobMapPin(
          job: job,
          property: property,
          customer: customer,
          technician: technician,
          addressLabel: property?.fullAddress.isNotEmpty == true
              ? property!.fullAddress
              : (property?.address ?? 'Address unavailable'),
          point: point,
          needsGeocode: needsGeocode && geocodeQuery.isNotEmpty,
          geocodeQuery: geocodeQuery,
        ),
      );
    }

    pins.sort((a, b) => a.job.startTime.compareTo(b.job.startTime));
    return pins;
  }
}
